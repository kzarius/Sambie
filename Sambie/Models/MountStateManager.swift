//
//  MountStateManager.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/25/25.
//

import SwiftData
import SwiftUI

/// Manages the state of mounts, including their connection status and any errors.
@MainActor
@Observable
final class MountStateManager {
    
    // MARK: - Properties
    struct MountState: Equatable {
        var status: ConnectionStatus = .disconnected
        var errors: [String] = []
        var reconnectAttempts: Int = 0
        var nextReconnectAt: Date?
        // Tracks the first time the server was unreachable for this mount:
        var serverUnreachableSince: Date? = nil
        // A mount is a zombie if it appears mounted but the server is consistently unreachable.
        var isForceUnmounting: Bool = false
        var isZombie: Bool {
            self.serverUnreachableSince != nil &&
            self.status == .connected
        }
    }
    
    private var states: [PersistentIdentifier: MountState] = [:]
    
    
    // MARK: - State Management
    /// Gets or sets the full state for a specific mount.
    subscript(mountID: PersistentIdentifier) -> MountState {
        get { self.states[mountID, default: MountState()] }
        set { self.states[mountID] = newValue }
    }
    
    func getState(for mountID: PersistentIdentifier) -> MountState {
        self.states[mountID] ?? MountState()
    }
    
    /// Sets the reconnect attempt count and next reconnect time for a specific mount.
    func setReconnectAttempt(_ attempt: Int, nextAt: Date, for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil {
            self.states[mountID] = MountState()
        }
        self.states[mountID]?.reconnectAttempts = attempt
        self.states[mountID]?.nextReconnectAt = nextAt
    }
    
    /// Increments the reconnect attempt count and sets the next reconnect time for a specific mount.
    func resetReconnectAttempts(for mountID: PersistentIdentifier) {
        self[mountID].reconnectAttempts = 0
        self[mountID].nextReconnectAt = nil
    }
    
    
    // MARK: - Status Management
    /// Sets the connection status for a specific mount.
    func setStatus(_ status: ConnectionStatus, for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil {
            self.states[mountID] = MountState()
        }
        self.states[mountID]?.status = status
    }
    
    /// Sets whether the mount is currently being force-unmounted due to server unreachability.
    func setForceUnmounting(_ value: Bool, for mountID: PersistentIdentifier) {
        if states[mountID] == nil { states[mountID] = MountState() }
        states[mountID]?.isForceUnmounting = value
    }
    
    
    // MARK: - Unreachable Management
    /// If the server is unreachable, marks the mount as such and starts tracking how long it's been unreachable.
    func markServerUnreachable(for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil { self.states[mountID] = MountState() }
        // Only set the timestamp once — don't overwrite on subsequent calls:
        if self.states[mountID]?.serverUnreachableSince == nil {
            self.states[mountID]?.serverUnreachableSince = Date()
        }
    }

    /// Resets the unreachable status for a mount, clearing the timestamp and any zombie state.
    func clearServerUnreachable(for mountID: PersistentIdentifier) {
        self.states[mountID]?.serverUnreachableSince = nil
    }
    
    
    // MARK: - Error Management
    /// Sets the error messages for a specific mount.
    func setErrors(_ errors: [String], for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil {
            self.states[mountID] = MountState()
        }
        self.states[mountID]?.errors = errors
    }

    /// Adds an error message for a specific mount.
    func addError(_ error: String, for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil {
            self.states[mountID] = MountState()
        }
        self.states[mountID]?.errors.append(error)
    }

    /// Clears all errors for a specific mount.
    func clearErrors(for mountID: PersistentIdentifier) { self.states[mountID]?.errors = [] }
}
