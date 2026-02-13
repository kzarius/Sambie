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
            
            // Collect results and update state:
            for await (mountID, isMounted) in group {
                await self.stateManager.setStatus(
                    isMounted ? .connected : .disconnected,
                    for: mountID
                )
            }
        }
    }
    
    /// Checks and updates the status of all mounts.
    internal func updateAllStatuses() async {
        // Retrieve all mounts:
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Check each mount's status for changes at the same time:
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus).self) { group in
            // Add all check tasks to the group:
            for mountID in mountIDs {
                group.addTask {
                    await self.checkMountStatus(for: mountID)
                }
            }
            
            // Update state for any changed statuses:
            for await (mountID, recordedStatus, actualStatus) in group {
                // Double-check mount still exists before updating:
                guard await self.accessor.exists(id: mountID) else { continue }
                if actualStatus != recordedStatus {
                    await self.stateManager.setStatus(actualStatus, for: mountID)
                    
                    // Handle auto-reconnect if unexpectedly disconnected:
                    if actualStatus == .disconnected && recordedStatus == .connected {
                        await self.handleUnexpectedDisconnect(for: mountID)
                    }
                }
            }
        }
    }
    
    /// Checks the status of a single mount and returns the recorded and actual statuses.
    private func checkMountStatus(for mountID: PersistentIdentifier) async -> (PersistentIdentifier, ConnectionStatus, ConnectionStatus) {
        // Verify mount exists and is not new before checking:
        guard await self.accessor.exists(id: mountID),
              await self.accessor.getData(id: mountID)?.isNew == false else {
            // Mount was deleted or not yet saved, skip it:
            return (mountID, .disconnected, .disconnected)
        }
        
        // Get the current recorded status:
        let recordedStatus = await self.stateManager.getState(for: mountID).status
        
        // Skip if transitioning:
        guard recordedStatus != .connecting, recordedStatus != .disconnecting else {
            return (mountID, recordedStatus, recordedStatus)
        }
        
        // Check actual mount status:
        let isMounted = await MountClient(
            mountID: mountID,
            accessor: self.accessor,
            stateManager: self.stateManager
        ).isMounted()
        let actualStatus: ConnectionStatus = isMounted ? .connected : .disconnected
        
        return (mountID, recordedStatus, actualStatus)
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
