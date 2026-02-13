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
    
    // Network monitoring:
    internal var networkMonitor: NWPathMonitor?
    internal var isNetworkAvailable = true
    
    
    // MARK: - Initializer
    init(
        accessor: MountAccessor,
        stateManager: MountStateManager
    ) async {
        self.accessor = accessor
        self.stateManager = stateManager
        
        // Initialize all mount states in parallel:
        await self.initializeAllStatuses()
        await self.startNetworkMonitoring()
    }
    
    deinit {
        monitoringTask?.cancel()
        networkMonitor?.cancel()
    }
    
    
    // MARK: - Public Methods
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
}
