//
//  Mount+state.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/26/25.
//

import SwiftData
import SwiftUI

extension Mount {
    /// Conventience method to update the status and error of the mount.
    /// - Parameters:
    ///  - status: The new connection status.
    ///  - errors: An optional array of errors to append to the mount's error list. If not provided, clears existing errors.
    func updateState(
        status: ConnectionStatus,
        errors: [Error] = [],
        using stateManager: MountStateManager
    ) async {
        await stateManager.setStatus(status, for: self.persistentModelID)
        
        // Clear errors if none provided:
        if errors.isEmpty {
            await stateManager.clearErrors(for: self.persistentModelID)
            // Otherwise append them to the array:
        } else {
            await stateManager.setErrors(
                errors.map { $0.localizedDescription },
                for: self.persistentModelID
            )
        }
    }
    
    /// Adds an error message for this mount via the provided `MountStateManager`.
    func addError(
        _ error: Error,
        using stateManager: MountStateManager
    ) async {
        await stateManager.addError(error.localizedDescription, for: self.id)
    }
}
