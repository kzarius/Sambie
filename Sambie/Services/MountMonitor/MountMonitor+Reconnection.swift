//
//  MountMonitor+Reconnection.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/2/2026.
//

import Foundation
import SwiftData

/// Reconnection Extension - handles scheduling and managing reconnection attempts for mounts that have been disconnected.
extension MountMonitor {
    /// Schedule a reconnection attempt for a mount with exponential backoff.
    func scheduleReconnect(for mountID: PersistentIdentifier, attempt: Int) async {
        // Cancel any existing scheduled reconnect for this mount:
        scheduledReconnects[mountID]?.cancel()
        
        // Calculate the delay using exponential backoff:
        let baseDelay = await Config.Connection.Reconnection.baseDelay
        let multiplier = pow(2.0, Double(attempt))
        let uncappedDelay = baseDelay * multiplier
        let maxDelayInSeconds = await Config.Connection.Reconnection.maxMinutesDelay * 60.0
        let delay = min(uncappedDelay, maxDelayInSeconds)
        let nextReconnectAt = Date().addingTimeInterval(delay)
        
        // Schedule the reconnect attempt:
        await stateManager.setReconnectAttempt(attempt, nextAt: nextReconnectAt, for: mountID)
        
        await logger("Scheduled reconnect for mount in \(delay)s (attempt \(attempt))", level: .debug)
    }
    
    /// Reset the backoff timer for a mount.
    func resetBackoff(for mountID: PersistentIdentifier) async {
        await logger("⚠️ resetBackoff called for a mount", level: .warning)
        self.scheduledReconnects[mountID]?.cancel()
        await stateManager.resetReconnectAttempts(for: mountID)
    }
    
    /// Processes scheduled reconnections for mounts that have been disconnected.
    /// Iterates through all mounts, checking if the current time has passed their scheduled reconnect time.
    /// If a mount is eligible for reconnection (past its scheduled time, currently disconnected, and auto-reconnect enabled),
    /// attempts to reconnect it using the MountClient. If the reconnection fails, schedules the next attempt with exponential backoff.
    internal func processScheduledReconnects() async {
        let mountIDs = await self.accessor.getAllMountIDs()
        let now = Date()
        
        for mountID in mountIDs {
            let state = await self.stateManager.getState(for: mountID)
            
            // Only attempt reconnect if we're past the scheduled time and currently disconnected, and we're not force-unmounting:
            guard let nextReconnectAt = state.nextReconnectAt,
                  nextReconnectAt <= now,
                  state.status == .disconnected,
                  !state.isForceUnmounting else {
                if state.nextReconnectAt != nil {
                    await logger("⏱ [processScheduledReconnects] skipping a mount — status=\(state.status) isForceUnmounting=\(state.isForceUnmounting) nextReconnectAt=\(String(describing: state.nextReconnectAt))", level: .debug)
                }
                continue
            }
            
            // Check if auto-reconnect is still enabled before attempting:
            guard let mountData = await self.accessor.getData(id: mountID),
                  mountData.autoReconnect, await ReconnectPolicy.isEligible(path: self.currentNetworkPath) else {
                continue
            }
            
            await logger("Attempting reconnect for \(mountData.name) (attempt \(state.reconnectAttempts))", level: .info)
            
            // Attempt to mount:
            let client = await MountClient(
                mountID: mountID,
                accessor: self.accessor,
                stateManager: self.stateManager
            )
            await client.mount()
            
            // After the mount attempt, check the new status:
            let newState = await self.stateManager.getState(for: mountID)
            if newState.status == .disconnected {
                await self.scheduleReconnect(for: mountID, attempt: state.reconnectAttempts + 1)
            }
        }
    }

    /// Immediately attempts to reconnect all auto-reconnect mounts that are disconnected at startup.
    internal func scheduleStartupReconnect(for mountID: PersistentIdentifier) async {
        
        // Check for mounts that should be auto-reconnected on startup:
        guard let mountData = await self.accessor.getData(id: mountID),
              mountData.autoReconnect, await ReconnectPolicy.isEligible(path: self.currentNetworkPath) else {
            return
        }
        
        await logger("Startup reconnect scheduled for \(mountData.name)", level: .info)
        // Set nextReconnectAt to now so processScheduledReconnects picks it up immediately:
        await stateManager.setReconnectAttempt(0, nextAt: Date(), for: mountID)
    }
}
