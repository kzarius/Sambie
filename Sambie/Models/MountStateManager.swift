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
    
    
    // MARK: - Status Management
    /// Sets the connection status for a specific mount.
    func setStatus(_ status: ConnectionStatus, for mountID: PersistentIdentifier) {
        if self.states[mountID] == nil {
            self.states[mountID] = MountState()
        }
        self.states[mountID]?.status = status
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
