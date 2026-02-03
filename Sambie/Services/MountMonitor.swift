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
        
        // Fetch all mounts:
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Check each mount's status:
        for mountID in mountIDs {
            let isMounted = await MountClient(
                mountID: mountID,
                accessor: self.accessor,
                stateManager: self.stateManager
            ).isMounted()

            // Update state on the MainActor-managed state manager:
            await self.stateManager.setStatus(
                isMounted ? .connected : .disconnected,
                for: mountID
            )
        }
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
    /// Checks and updates the status of all mounts.
    private func updateAllStatuses() async {
        // Retrieve all mounts:
        let mountIDs = await self.accessor.getAllMountIDs()
        
        // Check each mount's status for changes:
        for mountID in mountIDs {
            // Get the current recorded status:
            let recordedStatus = await self.stateManager.getState(for: mountID).status
            
            // Skip updates if mount is actively connecting/disconnecting:
            if recordedStatus == .connecting || recordedStatus == .disconnecting {
                continue
            }
            
            // Determine whether the actual mount state differs from the manager's recorded transient state:
            let actualStatus: ConnectionStatus = await MountClient(
                mountID: mountID,
                accessor: self.accessor,
                stateManager: self.stateManager
            ).isMounted() ? .connected : .disconnected
            
            // Update if there's a discrepancy:
            if actualStatus != recordedStatus {
                await self.stateManager.setStatus(actualStatus, for: mountID)
            }
        }
    }
}
