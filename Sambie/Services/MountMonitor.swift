//
//  MountMonitor.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI

actor MountMonitor {
    
    // MARK: - Properties
    private let accessor: MountAccessor
    private let stateManager: MountStateManager
    private var monitoringTask: Task<Void, Never>?
    private let checkInterval: TimeInterval = Config.Connection.checkMountInterval
    
    
    // MARK: - Initializer
    init(
        accessor: MountAccessor,
        stateManager: MountStateManager
    ) async {
        self.accessor = accessor
        self.stateManager = stateManager
        
        // Initialize all mount states in parallel:
        await self.initializeAllStatuses()
    }
    
    deinit { monitoringTask?.cancel() }
    
    
    // MARK: - Public Methods
    func startMonitoring() async {
        guard self.monitoringTask == nil else { return }
        
        self.monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.checkInterval))
                guard !Task.isCancelled else { break }
                await self.updateAllStatuses()
            }
        }
    }
    
    
    // MARK: - Private Methods
    /// Initializes the status of all mounts in parallel during actor initialization.
    private func initializeAllStatuses() async {
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
    private func updateAllStatuses() async {
        // Retrieve all mounts:
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Check each mount's status for changes at the same time:
        await withTaskGroup(of: (PersistentIdentifier, ConnectionStatus, ConnectionStatus).self) { group in
            // Add all check tasks to the group:
            for mountID in mountIDs {
                group.addTask {
                    do {
                        // Verify mount exists and is not new before checking:
                        guard await self.accessor.exists(id: mountID),
                              try await self.accessor.getData(id: mountID).isNew == false else {
                            // Mount was deleted or not yet saved, skip it:
                            return (mountID, .disconnected, .disconnected)
                        }
                    } catch {
                        // Failed to get mount data, skip it:
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
            }
            
            // Update state for any changed statuses:
            for await (mountID, recordedStatus, actualStatus) in group {
                // Double-check mount still exists before updating:
                guard await self.accessor.exists(id: mountID) else { continue }
                if actualStatus != recordedStatus {
                    await self.stateManager.setStatus(actualStatus, for: mountID)
                }
            }
        }
    }
}
