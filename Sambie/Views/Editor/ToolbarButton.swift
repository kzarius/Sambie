//
//  ToolbarButton.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/9/25.
//

import SwiftUI

/// A button used in toolbars, with optional confirmation dialog support.
struct ToolbarButton: View {
    
    // MARK: - Properties
    let title: String
    let action: () -> Void
    let color: Color
    let dialog: ConfirmationDialogModel?
    let onError: ((Error) -> Void)?
    
    @State private var showDialog = false
    
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    
    
    // MARK: - Initializer
    init(
        title: String,
        color: Color = Config.UI.Colors.primary,
        dialog: ConfirmationDialogModel? = nil,
        onError: ((Error) -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.dialog = dialog
        self.onError = onError
        self.action = action
    }
    
    
    // MARK: - Convenience Initializers
    /// Initializer for actions that can throw errors
    init(
        title: String,
        color: Color = Config.UI.Colors.primary,
        dialog: ConfirmationDialogModel? = nil,
        validationErrors: Binding<[Error]>,
        action: @escaping () throws -> Void
    ) {
        self.init(
            title: title,
            color: color,
            dialog: dialog,
            onError: { error in
                validationErrors.wrappedValue = [error]
            },
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
    
    /// Initializer for async actions that can throw errors
    init(
        title: String,
        color: Color = Config.UI.Colors.primary,
        dialog: ConfirmationDialogModel? = nil,
        validationErrors: Binding<[Error]>,
        action: @escaping () async throws -> Void
    ) {
        self.init(
            title: title,
            color: color,
            dialog: dialog,
            onError: { error in
                validationErrors.wrappedValue = [error]
            },
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
    
    
    // MARK: - Body
    var body: some View {
        Button {
            // Show confirmation dialog if provided:
            if self.dialog != nil { self.showDialog = true }
            
            // Otherwise, go ahead and run the main action:
            else { self.action() }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.padding + self.horizontalPadding)
                .padding(.vertical, self.padding)
                .background(
                    RoundedRectangle(cornerRadius: self.cornerRadius)
                        .fill(self.color)
                )
        }
        
        // Styling:
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        
        // Confirmation Dialog:
        .confirmationDialog(
            self.dialog?.title ?? "",
            isPresented: self.$showDialog,
            titleVisibility: .visible
        ) {
            // Dialog buttons:
            if let items = self.dialog?.items {
                ForEach(items) { item in
                    Button(item.label, role: item.role) {
                        // Execute dialog item action first (may throw):
                        if let itemAction = item.action {
                            itemAction()
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(self.dialog?.message ?? "")
        }
    }
}
