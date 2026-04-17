//
//  MountMonitor+Status.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/2/2026.
//

import Foundation
import SwiftData

/// Status Updates Extension - Handles all logic related to checking and updating the status of mounts.
extension MountMonitor {
    /// Initializes the status of all mounts in parallel during actor initialization.
    internal func initializeAllStatuses() async {
        // Get all mount IDs from the accessor:
        let statuses = await self.getAllMountStatuses()
        
        // Do the checks:
        for (mountID, _, actualStatus) in statuses {
            if actualStatus == .connected {
                await self.stateManager.setStatus(.connected, for: mountID)
            } else {
                await self.stateManager.setStatus(.disconnected, for: mountID)
                await self.scheduleStartupReconnect(for: mountID)
            }
        }
    }
    
    /// Sets the initial connection status for all mounts in parallel during actor startup.
    /// Only determines if each mount is already active in the OS — no reconnect or zombie logic.
    internal func updateAllStatuses() async {
        // Get all mount IDs from the accessor:
        let statuses = await self.getAllMountStatuses()
        
        for (mountID, recordedStatus, actualStatus) in statuses {
            // Make sure it still exists before updating:
            guard await self.accessor.exists(id: mountID) else { continue }
            
            // Check if the status has changed, and update it if so:
            if actualStatus != recordedStatus {
                await self.stateManager.setStatus(actualStatus, for: mountID)
                
                // If it was unexpectedly disconnected, trigger the flow:
                if actualStatus == .disconnected, recordedStatus == .connected {
                    let state = await self.stateManager.getState(for: mountID)
                    guard !state.isForceUnmounting else { continue }
                    await self.handleUnexpectedDisconnect(for: mountID)
                }
                
                // If the mount is now disconnected, schedule a reconnect if needed:
                if actualStatus != .connected {
                    await self.stateManager.setStatus(.disconnected, for: mountID)
                    await self.scheduleStartupReconnect(for: mountID)
                }
            }
        }
    }
    
    /// The main periodic status cycle. Runs both mount-level and host-level checks concurrently.
    /// Called by the monitoring timer on each tick.
    internal func runStatusCycle() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.updateAllStatuses() }
            group.addTask { await self.checkAllHostReachability() }
        }
    }
    
    /// Fetches the recorded and actual OS-level mount status for all mounts in parallel.
    private func getAllMountStatuses() async -> [(PersistentIdentifier, ConnectionStatus, ConnectionStatus)] {
        // Get all mount IDs from the accessor:
        let mountIDs = await self.accessor.getMountIDs().values.flatMap { $0 }

        var results: [(PersistentIdentifier, ConnectionStatus, ConnectionStatus)] = []
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus).self) { group in
            for mountID in mountIDs {
                group.addTask { await self.fetchMountStatus(for: mountID) }
            }
            for await result in group {
                results.append(result)
            }
        }
        return results
    }
    
    /// Checks the OS-level mount status for a single mount.
    /// Returns `(mountID, recordedStatus, actualStatus)`.
    private func fetchMountStatus(for mountID: PersistentIdentifier) async -> (PersistentIdentifier, ConnectionStatus, ConnectionStatus) {
        // Skip new or non-existent mounts:
        guard await self.accessor.exists(id: mountID),
              await self.accessor.getData(id: mountID)?.isNew == false else {
            return (mountID, .disconnected, .disconnected)
        }
        
        // Retrieve the recorded status from the state manager:
        let recordedStatus = await self.stateManager.getState(for: mountID).status
        guard recordedStatus != .connecting, recordedStatus != .disconnecting else {
            return (mountID, recordedStatus, recordedStatus)
        }
        
        let isMounted = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        ).isMounted()
        
        return (
            mountID,
            recordedStatus,
            isMounted ? .connected : .disconnected
        )
    }
    
    // MARK: - Host-Level Reachability Checks
    /// Checks port reachability for each host that has at least one connected mount.
    /// If a host is unreachable, all of its connected mounts are pushed into zombie handling.
    private func checkAllHostReachability() async {
        var connectedHosts: [(PersistentIdentifier, [PersistentIdentifier])] = []
        var mountsNeedingZombieUnmount: [PersistentIdentifier] = []
        // Get all mounts grouped by host:
        let mountsByHost = await self.accessor.getMountIDs()

        // Collect hosts that have at least one connected mount:
        for (hostID, mountIDs) in mountsByHost {
            let connectedMounts = await self.connectedMounts(from: mountIDs)
            guard !connectedMounts.isEmpty else { continue }
            connectedHosts.append((hostID, connectedMounts))
        }

        // Check each host's reachability in parallel:
        await withTaskGroup(of: [PersistentIdentifier].self) { group in
            for (hostID, connectedMountIDs) in connectedHosts {
                group.addTask {
                    // Returns a list of mount IDs if the host is unresponsive.
                    await self.checkHostForBites(
                        hostID: hostID,
                        connectedMountIDs: connectedMountIDs
                    )
                }
            }
            
            // zombieMountIDs is the collection of returned mountIDs from checkHostForBites() in the group task.
            for await zombieMountIDs in group {
                mountsNeedingZombieUnmount.append(contentsOf: zombieMountIDs)
            }
        }

        // Run zombie unmounts in parallel:
        await withTaskGroup(of: Void.self) { group in
            for mountID in mountsNeedingZombieUnmount {
                group.addTask { await self.runZombieUnmount(for: mountID) }
            }
        }
    }

    /// Checks a single host's port reachability and returns any mount IDs that need zombie unmounting.
    private func checkHostForBites(
        hostID: PersistentIdentifier,
        connectedMountIDs: [PersistentIdentifier]
    ) async -> [PersistentIdentifier] {
        guard let hostData = await self.accessor.getHostData(for: hostID) else { return [] }

        // Check if the host is reachable:
        let isReachable = await (try? Host.checkPortAccessible(
            host: hostData.hostname,
            port: hostData.port
        )) != nil

        // If it's reachable, clear any existing unreachable status and return:
        if isReachable {
            for mountID in connectedMountIDs {
                await self.stateManager.clearServerUnreachable(for: mountID)
            }
            return []
        }

        // If it's not reachable, prepare zombie unmounts for all connected mounts:
        var zombieIDs: [PersistentIdentifier] = []
        for mountID in connectedMountIDs {
            if let id = await self.prepareZombieUnmount(for: mountID) {
                zombieIDs.append(id)
            }
        }
        return zombieIDs
    }

    /// Returns the subset of the given mount IDs that are currently connected.
    private func connectedMounts(from mountIDs: [PersistentIdentifier]) async -> [PersistentIdentifier] {
        var connected: [PersistentIdentifier] = []
        for mountID in mountIDs {
            let status = await self.stateManager.getState(for: mountID).status
            if status == .connected { connected.append(mountID) }
        }
        return connected
    }
    
    /// Handles auto-reconnect logic for an unexpectedly disconnected mount.
    /// Marks the mount as unexpectedly disconnected, which will trigger the reconnect UI, and schedules the first reconnect attempt.
    private func handleUnexpectedDisconnect(for mountID: PersistentIdentifier) async {
        // Mark the mount as unexpectedly disconnected to trigger the reconnect UI:
        try? await self.accessor.markUnexpectedDisconnect(mountID)
        
        // Check if auto-reconnect is enabled, and that we're on a trusted network:
        guard let mountData = await self.accessor.getData(id: mountID),
              mountData.autoReconnect, await ReconnectPolicy.isEligible(path: self.currentNetworkPath) else { return }

        // Reset reconnect attempts and schedule a reconnect:
        await self.stateManager.resetReconnectAttempts(for: mountID)
        await self.scheduleReconnect(for: mountID, attempt: 0)
    }
    
    /// Marks the server as unreachable for a connected mount and returns the mountID if the zombie timeout has been exceeded.
    /// Returns nil if the mount is not yet ready for a force unmount.
    private func prepareZombieUnmount(for mountID: PersistentIdentifier) async -> PersistentIdentifier? {
        await self.stateManager.markServerUnreachable(for: mountID)

        let state = await self.stateManager.getState(for: mountID)
        guard let unreachableSince = state.serverUnreachableSince else { return nil }

        let zombieTimeout = await Config.Connection.mountTimeout
        let elapsed = Date().timeIntervalSince(unreachableSince)

        guard elapsed >= zombieTimeout, !state.isForceUnmounting else { return nil }

        await logger("🧟 Mount \(mountID) has been unreachable for \(Int(elapsed))s — queuing zombie unmount", level: .warning)
        return mountID
    }

    /// Force unmounts a zombie mount and schedules a reconnect if auto-reconnect is enabled.
    private func runZombieUnmount(for mountID: PersistentIdentifier) async {
        // Force unmount it:
        let client = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.forceUnmountZombie()

        await self.stateManager.clearServerUnreachable(for: mountID)

        // Check if auto-reconnect is enabled and we're on a trusted network before scheduling a reconnect:
        guard let mountData = await self.accessor.getData(id: mountID),
              mountData.autoReconnect, await ReconnectPolicy.isEligible(path: self.currentNetworkPath) else { return }

        await self.stateManager.resetReconnectAttempts(for: mountID)
        await self.scheduleReconnect(for: mountID, attempt: 0)
    }
}
