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
        // Use the accessor's new closure method to handle concurrency:
        await self.accessor.getMountIDs(concurrently: true) { mountID in
            
            let (_, _, actualStatus) = await self.fetchMountStatus(for: mountID)
            
            if actualStatus == .connected {
                await self.stateManager.setStatus(.connected, for: mountID)
            } else {
                await self.stateManager.setStatus(.disconnected, for: mountID)
                await self.scheduleStartupReconnect(for: mountID)
            }
        }
    }
    
    /// The main periodic status cycle. Fetches all mounts grouped by host, checks host reachability, and updates individual mount statuses. Called by the monitoring timer on each tick.
    internal func runStatusCycle() async {
        // Get all mounts grouped by host:
        let mountsByHost = await self.accessor.getMountIDs()
        
        // Go through each host group in parallel:
        await withTaskGroup(of: Void.self) { group in
            for (hostID, mountIDs) in mountsByHost {
                group.addTask {
                    // Check host reachability and mount statuses:
                    await self.processHostGroup(hostID: hostID, mountIDs: mountIDs)
                }
            }
        }
    }
    
    /// Processes a single host group: checks host reachability, then processes the OS-level status of each of its mounts.
    private func processHostGroup(hostID: PersistentIdentifier, mountIDs: [PersistentIdentifier]) async {
        
        // 1. Check reachability of the underlying host port:
        var isReachable = false
        if let hostData = await self.accessor.getHostData(for: hostID) {
            do {
                try await Host.checkPortAccessible(host: hostData.hostname, port: hostData.port)
                isReachable = true
                
            // Port is closed or network is down:
            } catch {
                isReachable = false
            }
        }
        
        // 2. Check the OS-level status for all mounts under this host in parallel:
        var mountStatuses: [(PersistentIdentifier, ConnectionStatus, ConnectionStatus)] = []
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus).self) { group in
            
            for mountID in mountIDs {
                // Returns (mountID, recordedStatus, actualStatus) for each mount:
                group.addTask { await self.fetchMountStatus(for: mountID) }
            }
            
            // Collect the results:
            for await statusTuple in group {
                mountStatuses.append(statusTuple)
            }
        }
        
        // 3. Process each mount given the host's reachability and its actual OS status:
        for (mountID, recordedStatus, actualStatus) in mountStatuses {
            await self.processMountStatus(
                mountID: mountID,
                recordedStatus: recordedStatus,
                actualStatus: actualStatus,
                isHostReachable: isReachable
            )
        }
    }

    /// Updates state, handles unexpected disconnects, and manages zombie unmounts for a single mount.
    private func processMountStatus(
        mountID: PersistentIdentifier,
        recordedStatus: ConnectionStatus,
        actualStatus: ConnectionStatus,
        isHostReachable: Bool
    ) async {
        // Ensure the mount still exists:
        guard await self.accessor.exists(id: mountID) else { return }

        // 1. Check for immediate OS-level status changes:
        if actualStatus != recordedStatus {
            let summary = await self.accessor.summarize(id: mountID)
            await logger("[runStatusCycle] Mount `\(summary)` status changed: \(recordedStatus) -> \(actualStatus)", level: .info)
            await self.stateManager.setStatus(actualStatus, for: mountID)
            
            // Handle unexpected OS disconnects:
            if actualStatus == .disconnected, recordedStatus == .connected {
                let state = await self.stateManager.getState(for: mountID)
                
                // Skip scheduling if this was a zombie force-unmount:
                if !state.isForceUnmounting, state.serverUnreachableSince == nil {
                    await self.handleUnexpectedDisconnect(for: mountID)
                }
            }
            
            if actualStatus != .connected {
                await self.stateManager.setStatus(.disconnected, for: mountID)
            }
        }
        
        // 2. Handle ongoing states (Healthy Connected vs. Zombie):
        if actualStatus == .connected {
            if isHostReachable {
                
                // Healthy: Host is reachable, and OS shows it as connected:
                await self.stateManager.setStatus(.connected, for: mountID)
                await self.stateManager.clearErrors(for: mountID)
                await self.stateManager.resetReconnectAttempts(for: mountID)
                
                // Clears unreachable state if host recovers:
                await self.stateManager.clearServerUnreachable(for: mountID)
                self.clearScheduledReconnect(for: mountID)
                
            // Host is unreachable but OS still shows it as connected (most likely a zombie mount):
            } else {
                let state = await self.stateManager.getState(for: mountID)
                
                // Prevent parallel force-unmounts:
                guard !state.isForceUnmounting else { return }
                // Stamps the current time if not already set:
                await self.stateManager.markServerUnreachable(for: mountID)
                
                let updatedState = await self.stateManager.getState(for: mountID)
                if let unreachableSince = updatedState.serverUnreachableSince {
                    let elapsed = Date().timeIntervalSince(unreachableSince)
                    let zombieTimeout = await Config.Connection.mountTimeout
                    
                    // The elapsed time exceeds the zombie timeout, so we consider it a zombie and force unmount it:
                    if elapsed >= zombieTimeout {
                        let summary = await self.accessor.summarize(id: mountID)
                        await logger("[runStatusCycle] 🧟 Mount `\(summary)` unreachable for \(Int(elapsed))s (networkDown: \(!self.isNetworkAvailable)) — queuing zombie unmount", level: .warning)
                        
                        Task { await self.runZombieUnmount(for: mountID) }
                    }
                }
            }
            
        // Not connected:
        } else {
            await self.stateManager.clearServerUnreachable(for: mountID)
        }
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
        
        let summary = await self.accessor.summarize(id: mountID)
        await logger("[runZombieUnmount] Scheduling reconnect for mount `\(summary)` after zombie unmount. autoReconnect: \(mountData.autoReconnect)", level: .info)

        await self.stateManager.resetReconnectAttempts(for: mountID)
        await self.scheduleReconnect(for: mountID, attempt: 0)
    }
}
