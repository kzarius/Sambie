//
//  MountMonitor.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import Network
import SwiftData
import SwiftUI

actor MountMonitor {
    
    // MARK: - Properties
    internal let accessor: MountAccessor
    internal let stateManager: MountStateManager
    internal var monitoringTask: Task<Void, Never>?
    internal let checkInterval: TimeInterval = Config.Connection.checkMountInterval
    
    // Reconnection scheduling:
    internal var scheduledReconnects: [PersistentIdentifier: Task<Void, Never>] = [:]
    internal var mountsNeedingZombieUnmount: [PersistentIdentifier] = []
    
    // Network monitoring:
    internal var networkMonitor: NWPathMonitor?
    internal var isNetworkAvailable = true
    internal var currentNetworkPath: NWPath? = nil
    
    
    // MARK: - Initializer
    init(
        accessor: MountAccessor,
        stateManager: MountStateManager
    ) async {
        self.accessor = accessor
        self.stateManager = stateManager
        
        // Initialize all mount states in parallel:
        await self.startNetworkMonitoring()
        try? await Task.sleep(for: .milliseconds(300))
        await self.initializeAllStatuses()
        
        // Fire an immediate reconnect pass in the background without blocking init:
        Task { await self.processScheduledReconnects() }
    }
    
    deinit {
        monitoringTask?.cancel()
        networkMonitor?.cancel()
    }
    
    
    // MARK: - Public Methods
    /// Starts the monitoring loop that periodically checks the status of all mounts and processes scheduled reconnects.
    func startMonitoring() async {
        guard self.monitoringTask == nil else { return }
        
        self.monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.checkInterval))
                guard !Task.isCancelled else { break }
                await self.updateAllStatuses()
                await self.processScheduledReconnects()
            }
        }
    }
    
    /// Stops the monitoring loop.
    func cleanupMount(id mountID: PersistentIdentifier) async {
        // Cancel any pending reconnect task for this mount:
        scheduledReconnects[mountID]?.cancel()
        scheduledReconnects.removeValue(forKey: mountID)
        
        // Clear its state:
        await stateManager.clearErrors(for: mountID)
        await stateManager.clearServerUnreachable(for: mountID)
        await stateManager.resetReconnectAttempts(for: mountID)
    }
}
