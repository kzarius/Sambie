//
//  ConfirmationDialogModel.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/19/25.
//

import SwiftUI

/// Model representing a confirmation dialog with a title, message, and action items.
struct ConfirmationDialogModel {
    let title: String
    let message: String
    let items: [ConfirmationDialogItem]
}

/// Represents a button that performs an action in a confirmation dialog.
struct ConfirmationDialogItem: Identifiable {
    
    // MARK: - Properties
    let id = UUID()
    let label: String
    let role: ButtonRole?
    let action: (() -> Void)?
    
    
    // MARK: - Initializers
    init(
        label: String,
        role: ButtonRole? = nil,
        action: (() -> Void)? = nil
    ) {
        self.label = label
        self.role = role
        self.action = action
    }
}

/// Extension for creating confirmation dialog items with validation error handling.
extension ConfirmationDialogItem {
    /// Initializer for actions that can throw errors.
    init(
        label: String,
        role: ButtonRole? = nil,
        validationErrors: Binding<[Error]>,
        action: @escaping () throws -> Void
    ) {
        self.init(
            label: label,
            role: role,
            action: {
                do {
                    try action()
                    validationErrors.wrappedValue.removeAll()
                } catch {
                    validationErrors.wrappedValue = [error]
                }
            }
        )
    }

    /// Initializer for actions that can throw errors.
    init(
        label: String,
        role: ButtonRole? = nil,
        validationErrors: Binding<[Error]>,
        action: @escaping () async throws -> Void
    ) {
        self.init(
            label: label,
            role: role,
            action: {
                Task {
                    do {
                        try await action()
                        validationErrors.wrappedValue.removeAll()
                    } catch {
                        validationErrors.wrappedValue = [error]
                    }
                }
            }
        )
    }
}
