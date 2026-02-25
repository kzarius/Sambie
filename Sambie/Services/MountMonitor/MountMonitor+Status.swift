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
        
        // Check each mount's status in parallel:
        await withTaskGroup(of: (PersistentIdentifier, Bool).self) { group in
            for mountID in mountIDs {
                group.addTask {
                    let isMounted = await MountClient(
                        mountID: mountID,
                        accessor: self.accessor,
                        stateManager: self.stateManager
                    ).isMounted()
                    return (mountID, isMounted)
                }
            }
            
            // Update state and schedule reconnects for any disconnected mounts:
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
    internal func updateAllStatuses() async {
        // Retrieve all mounts:
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Check each mount's status for changes at the same time:
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus, Bool).self) { group in
            // Add all check tasks to the group:
            for mountID in mountIDs {
                group.addTask {
                    await self.checkMountStatus(for: mountID)
                }
            }
            
            // Update state for any changed statuses:
            for await (mountID, recordedStatus, actualStatus, isServerReachable) in group {
                // Double-check mount still exists before updating:
                guard await self.accessor.exists(id: mountID) else { continue }
                
                // Handle status change if different from recorded:
                if actualStatus != recordedStatus {
                    await self.stateManager.setStatus(actualStatus, for: mountID)
                    
                    // Handle auto-reconnect if unexpectedly disconnected:
                    if (actualStatus == .disconnected) && (recordedStatus == .connected) {
                        await self.handleUnexpectedDisconnect(for: mountID)
                    }
                }
                
                // Handle server unreachable if mount is connected:
                if (actualStatus == .connected) && !isServerReachable {
                    await self.handleServerUnreachable(for: mountID)
                } else {
                    await self.stateManager.clearServerUnreachable(for: mountID)
                }
            }
        }
    }
    
    /// Checks the status of a single mount and returns the recorded, actual status, and server reachability.
    private func checkMountStatus(for mountID: PersistentIdentifier) async -> (PersistentIdentifier, ConnectionStatus, ConnectionStatus, Bool) {
        // Verify mount exists and is not new before checking:
        guard await self.accessor.exists(id: mountID),
              await self.accessor.getData(id: mountID)?.isNew == false else {
            // Mount was deleted or not yet saved, skip it:
            return (mountID, .disconnected, .disconnected, true)
        }
        
        // Get the current recorded status:
        let recordedStatus = await self.stateManager.getState(for: mountID).status
        
        // Skip if transitioning:
        guard recordedStatus != .connecting, recordedStatus != .disconnecting else {
            return (mountID, recordedStatus, recordedStatus, true)
        }
        
        // Check actual mount status:
        let isMounted = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        ).isMounted()
        let actualStatus: ConnectionStatus = isMounted ? .connected : .disconnected
        
        // Only check server reachability if the mount is currently connected:
        var isServerReachable = true
        if isMounted, let mountData = await self.accessor.getData(id: mountID) {
            isServerReachable = await SambaMount.isServerReachable(mountData: mountData)
        }
        
        return (mountID, recordedStatus, actualStatus, isServerReachable)
    }
    
    /// Handles a single consecutive server-unreachable event for a connected mount.
    /// After `unreachableForceUnmountThreshold` consecutive failures, forces an unmount.
    private func handleServerUnreachable(for mountID: PersistentIdentifier) async {
        await self.stateManager.markServerUnreachable(for: mountID)

        let state = await self.stateManager.getState(for: mountID)
        guard let since = state.serverUnreachableSince else { return }

        let elapsed = Date().timeIntervalSince(since)
        let timeout = await Config.Connection.mountTimeout

        await logger(
            "Server unreachable for mount \(mountID) — \(Int(elapsed))s / \(Int(timeout))s timeout",
            level: .warning
        )

        guard elapsed >= timeout else { return }

        await logger(
            "Mount timeout exceeded (\(Int(elapsed))s) — forcing zombie unmount for \(mountID)",
            level: .warning
        )

        await self.stateManager.clearServerUnreachable(for: mountID)

        let client = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.forceUnmountZombie()
    }
    
    /// Handles auto-reconnect logic for an unexpectedly disconnected mount.
    private func handleUnexpectedDisconnect(for mountID: PersistentIdentifier) async {
        // Mark as unexpected disconnect in the persisted model
        try? await self.accessor.markUnexpectedDisconnect(mountID)
        
        // Check if auto-reconnect is enabled:
        if let mountData = await self.accessor.getData(id: mountID),
           mountData.autoReconnect {
            await logger("Auto-reconnecting \(mountData.name)...", level: .info)
            Task {
                await MountClient(
                    mountID: mountID,
                    accessor: self.accessor,
                    stateManager: self.stateManager
                ).mount()
            }
        }
    }
}
