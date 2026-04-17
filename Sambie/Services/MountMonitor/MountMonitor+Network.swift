//
//  MountMonitor+Network.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/2/2026.
//

import Foundation
import Network

/// Network Monitoring Extension - Handles network connectivity changes to manage auto-reconnect mounts.
extension MountMonitor {
    /// Start monitoring network connectivity.
    internal func startNetworkMonitoring() async {
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { await self?.doNetworkPathUpdate(path: path) }
        }
        self.networkMonitor?.start(queue: .global(qos: .utility))
        
        await logger("Network monitoring started", level: .debug)
    }
    
    /// Processes network path updates from NWPathMonitor.
    /// This method checks if the network has transitioned from unavailable to available, and if so, it runs the status cycle and processes scheduled reconnects immediately. On network restore, immediately triggers a full status cycle and reconnect pass rather than waiting for the next timer tick.
    /// - Parameter path: The updated NWPath from the monitor.
    private func doNetworkPathUpdate(path: NWPath) async {
        let wasAvailable = self.isNetworkAvailable
        self.isNetworkAvailable = path.status == .satisfied
        self.currentNetworkPath = path
        
        // Only trigger reconnects if we transitioned from unavailable to available:
        guard !wasAvailable && self.isNetworkAvailable else { return }
        
        await logger("⚡ Network restored — triggering immediate status cycle and reconnect pass", level: .info)
        await self.runStatusCycle()
        await self.doScheduledReconnects()
    }
}
