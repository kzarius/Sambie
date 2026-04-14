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
    /// Cancels any existing scheduled task for this mount and creates a new one that fires after the calculated delay.
    func scheduleReconnect(for mountID: PersistentIdentifier, attempt: Int) async {
        // Cancel any existing scheduled reconnect for this mount:
        scheduledReconnects[mountID]?.cancel()

        // Calculate the delay using exponential backoff:
        let baseDelay = await Config.Connection.Reconnection.baseDelay
        let multiplier = pow(2.0, Double(attempt))
        let uncappedDelay = baseDelay * multiplier
        let maxDelayInSeconds = await Config.Connection.Reconnection.maxMinutesDelay * 60.0
        let delay = min(uncappedDelay, maxDelayInSeconds)

        await logger("Scheduled reconnect for mount in \(delay)s (attempt \(attempt))", level: .debug)
        await stateManager.setReconnectAttempt(attempt, nextAt: Date().addingTimeInterval(delay), for: mountID)

        // Create a task that fires after the delay:
        scheduledReconnects[mountID] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            await self.attemptReconnect(for: mountID, attempt: attempt)
        }
    }
    
    /// Reset the backoff timer for a mount.
    func resetBackoff(for mountID: PersistentIdentifier) async {
        await logger("⚠️ resetBackoff called for a mount", level: .warning)
        scheduledReconnects[mountID]?.cancel()
        scheduledReconnects.removeValue(forKey: mountID)
        await stateManager.resetReconnectAttempts(for: mountID)
    }
    
    /// Performs a single reconnect attempt for a mount.
    /// If the mount is no longer eligible or already connected, the task exits cleanly.
    /// If the reconnect fails, the next attempt is scheduled with incremented backoff.
    private func attemptReconnect(
        for mountID: PersistentIdentifier,
        attempt: Int
    ) async {
        let state = await stateManager.getState(for: mountID)

        // Bail if the mount is no longer disconnected or is being force-unmounted:
        guard state.status == ConnectionStatus.disconnected,
              !state.isForceUnmounting else { return }

        // Bail if auto-reconnect has been disabled or we're on an untrusted network:
        guard let mountData = await accessor.getData(id: mountID),
              mountData.autoReconnect,
              await ReconnectPolicy.isEligible(path: currentNetworkPath) else { return }

        await logger("Attempting reconnect for \(mountData.name) (attempt \(attempt))", level: .info)

        // Attempt the reconnect:
        await MountClient(
            mountID: mountID,
            accessor: accessor,
            stateManager: stateManager
        ).mount()

        // Schedule the next attempt if still disconnected:
        let newState = await stateManager.getState(for: mountID)
        if newState.status == ConnectionStatus.disconnected {
            await scheduleReconnect(for: mountID, attempt: attempt + 1)
        }
    }

    /// Immediately attempts to reconnect all auto-reconnect mounts that are disconnected at startup.
    internal func scheduleStartupReconnect(for mountID: PersistentIdentifier) async {
        guard let mountData = await accessor.getData(id: mountID),
              mountData.autoReconnect,
              await ReconnectPolicy.isEligible(path: currentNetworkPath) else { return }

        await logger("Startup reconnect scheduled for \(mountData.name)", level: .info)
        await scheduleReconnect(for: mountID, attempt: 0)
    }
    
    /// Called on network restore or cycle refresh — re-arms any disconnected auto-reconnect mounts that don't already have a pending task (e.g. their task was cancelled during network loss).
    internal func processScheduledReconnects() async {
        let mountIDs = await accessor.getMountIDs().values.flatMap { $0 }

        for mountID in mountIDs {
            // Skip if there's already a live task for this mount:
            guard scheduledReconnects[mountID] == nil ||
                  scheduledReconnects[mountID]?.isCancelled == true else { continue }

            let state = await stateManager.getState(for: mountID)
            guard state.status == ConnectionStatus.disconnected,
                  !state.isForceUnmounting,
                  let mountData = await accessor.getData(id: mountID),
                  mountData.autoReconnect,
                  await ReconnectPolicy.isEligible(path: currentNetworkPath) else { continue }

            await scheduleReconnect(for: mountID, attempt: state.reconnectAttempts)
        }
    }
}
