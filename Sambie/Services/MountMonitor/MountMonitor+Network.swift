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
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { await self?.processNetworkPathUpdate(path: path) }
        }
        networkMonitor?.start(queue: .global(qos: .utility))
        
        await logger("Network monitoring started", level: .debug)
    }
    
    /// Processes network path updates from NWPathMonitor.
    /// Resets reconnection backoff for auto-reconnect mounts when network connectivity is restored.
    private func processNetworkPathUpdate(path: NWPath) async {
        let wasAvailable = self.isNetworkAvailable
        self.isNetworkAvailable = path.status == .satisfied
        self.currentNetworkPath = path
        
        guard !wasAvailable && self.isNetworkAvailable else { return }
        
        await logger("Network restored, resetting backoff for auto-reconnect mounts", level: .info)
        
        let mountIDs = await self.accessor.getAllMountIDs()
        for mountID in mountIDs {
            guard let mountData = await self.accessor.getData(id: mountID),
                  mountData.autoReconnect else {
                continue
            }
            
            let state = await self.stateManager.getState(for: mountID)
            guard state.status == .disconnected, !state.isForceUnmounting else {
                await logger("⚡ [network restore] skipping \(mountID) — status=\(state.status) isForceUnmounting=\(state.isForceUnmounting)", level: .debug)
                continue
            }
            
            await self.resetBackoff(for: mountID)
            await self.stateManager.setReconnectAttempt(0, nextAt: Date(), for: mountID)
        }
        
        // Immediately attempt reconnects rather than waiting for the next timer tick:
        Task { await self.processScheduledReconnects() }
    }
}
