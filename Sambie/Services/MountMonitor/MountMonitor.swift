//
//  MountMonitor.swift
//  Sambie
//
// FLOW:
// - On init, start network monitoring and initialize all mount statuses in parallel.
//   - Used to ensure we have network status before checking mounts, and to speed up initial status checks.
// - startMonitoring(): Called when mounts are loaded. Start a monitoring loop that runs every `checkInterval` seconds to:
//   - Check the status of all mounts and update their states.
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
        Task { await self.doScheduledReconnects() }
    }
    
    deinit {
        self.monitoringTask?.cancel()
        self.networkMonitor?.cancel()
    }
    
    
    // MARK: - Public Methods
    /// Starts the monitoring loop that periodically checks the status of all mounts and processes scheduled reconnects.
    func startMonitoring() async {
        guard self.monitoringTask == nil else { return }
        
        self.monitoringTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(self.checkInterval))
                } catch {
                    // Exit on cancellation:
                    break
                }
                guard !Task.isCancelled else { break }
                await self.runStatusCycle()
            }
            self.monitoringTask = nil
        }
    }
    
    /// Stops the monitoring loop./
    func stopMonitoring() { self.monitoringTask?.cancel() }
    
    /// Stops the monitoring loop.
    func cleanupMount(id mountID: PersistentIdentifier) async {
        // Cancel any pending reconnect task for this mount:
        self.scheduledReconnects[mountID]?.cancel()
        self.scheduledReconnects.removeValue(forKey: mountID)
        
        // Clear its state:
        await self.stateManager.clearErrors(for: mountID)
        await self.stateManager.clearServerUnreachable(for: mountID)
        await self.stateManager.resetReconnectAttempts(for: mountID)
    }
}
