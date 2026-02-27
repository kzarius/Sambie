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
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Initialize statuses in parallel using a task group to speed up the process, especially if there are many mounts:
        await withTaskGroup(of: (PersistentIdentifier, Bool).self) { group in
            for mountID in mountIDs {
                // Check each mount to see if it's mounted:
                group.addTask {
                    let isMounted = await MountClient(
                        mountID: mountID,
                        accessor: self.accessor,
                        stateManager: self.stateManager
                    ).isMounted()
                    return (mountID, isMounted)
                }
            }
            
            // Update the state manager with the initial status for each mount as results come in:
            for await (mountID, isMounted) in group {
                if isMounted {
                    await self.stateManager.setStatus(.connected, for: mountID)
                } else {
                    await self.stateManager.setStatus(.disconnected, for: mountID)
                    await self.scheduleStartupReconnect(for: mountID)
                }
            }
        }
    }
    
    /// Checks and updates the status of all mounts.
    /// This method is called periodically by the timer and performs the following steps for each mount:
    /// 1. Checks the actual mount status using MountClient.
    /// 2. Updates the state manager with the new status if it has changed.
    /// 3. If a mount has unexpectedly disconnected, marks it as such to trigger the reconnect UI and schedules a reconnect if enabled.
    /// 4. If a mount is connected but the server is unreachable, marks it as server unreachable and starts the timeout countdown for a potential zombie unmount.
    internal func updateAllStatuses() async {
        let mountIDs = await self.accessor.getAllMountIDs()
        // Reset each cycle:
        self.mountsNeedingZombieUnmount = []
        
        // Check and update the status of each mount in parallel using a task group:
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus, Bool).self) { group in
            for mountID in mountIDs {
                group.addTask {
                    await self.checkMountStatus(for: mountID)
                }
            }
            
            // Process the results as they come in, updating the state manager and handling any status changes or server unreachable conditions:
            for await (mountID, recordedStatus, actualStatus, isServerReachable) in group {
                guard await self.accessor.exists(id: mountID) else { continue }
                
                // Handle status changes:
                if actualStatus != recordedStatus {
                    await self.stateManager.setStatus(actualStatus, for: mountID)
                    
                    if actualStatus == .disconnected, recordedStatus == .connected {
                        let state = await self.stateManager.getState(for: mountID)
                        guard !state.isForceUnmounting else { continue }
                        await self.handleUnexpectedDisconnect(for: mountID)
                    }
                }
                
                // Handle server unreachable condition for connected mounts:
                if actualStatus == .connected, !isServerReachable {
                    if let mountID = await self.prepareZombieUnmount(for: mountID) {
                        mountsNeedingZombieUnmount.append(mountID)
                    }
                } else {
                    await self.stateManager.clearServerUnreachable(for: mountID)
                }
            }
        }
        
        // Run zombie unmounts in a separate task group so they don't block the status loop:
        await withTaskGroup(of: Void.self) { group in
            for mountID in mountsNeedingZombieUnmount {
                group.addTask {
                    await self.runZombieUnmount(for: mountID)
                }
            }
        }
    }
    
    /// Checks the status of a single mount and returns the recorded status, actual status, and server reachability.
    private func checkMountStatus(for mountID: PersistentIdentifier) async -> (PersistentIdentifier, ConnectionStatus, ConnectionStatus, Bool) {
        // Verify mount exists and is not new before checking:
        guard await self.accessor.exists(id: mountID),
              await self.accessor.getData(id: mountID)?.isNew == false else {
            return (mountID, .disconnected, .disconnected, true)
        }
        
        // Retrieve the recorded status from the state manager:
        let recordedStatus = await self.stateManager.getState(for: mountID).status
        guard recordedStatus != .connecting, recordedStatus != .disconnecting else {
            return (mountID, recordedStatus, recordedStatus, true)
        }
        
        let isMounted = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        ).isMounted()
        let actualStatus: ConnectionStatus = isMounted ? .connected : .disconnected
        
        // Check server reachability if the mount is connected:
        var isServerReachable = true
        if isMounted, let mountData = await self.accessor.getData(id: mountID) {
            isServerReachable = await SambaMount.isServerReachable(mountData: mountData)
        }
        
        return (mountID, recordedStatus, actualStatus, isServerReachable)
    }
    
    /// Handles auto-reconnect logic for an unexpectedly disconnected mount.
    /// Marks the mount as unexpectedly disconnected, which will trigger the reconnect UI, and schedules the first reconnect attempt.
    private func handleUnexpectedDisconnect(for mountID: PersistentIdentifier) async {
        // Mark the mount as unexpectedly disconnected to trigger the reconnect UI:
        try? await self.accessor.markUnexpectedDisconnect(mountID)
        
        // Check if auto-reconnect is enabled:
        guard let mountData = await self.accessor.getData(id: mountID),
              mountData.autoReconnect else { return }

        await logger("Unexpected disconnect for \(mountData.name) — scheduling reconnect", level: .info)
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
        let client = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.forceUnmountZombie()

        await self.stateManager.clearServerUnreachable(for: mountID)

        guard let mountData = await self.accessor.getData(id: mountID),
              mountData.autoReconnect else { return }

        await logger("🧟 Zombie unmount complete for \(mountData.name) — scheduling reconnect", level: .info)
        await self.stateManager.resetReconnectAttempts(for: mountID)
        await self.scheduleReconnect(for: mountID, attempt: 0)
    }
}
