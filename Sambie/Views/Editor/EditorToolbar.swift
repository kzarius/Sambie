//
//  EditorToolbar.swift
//  Sambie
//
//  Toolbar for the mount editor view and is a component of the EditorView. Handles actions like adding, saving, deleting mounts, and testing connections.
//
//  Created by Kaeo McKeague-Clark on 6/29/25.
//

import SwiftUI

struct EditorToolbar: ToolbarContent {
    
    // MARK: - Properties
    @Environment(\.modelContext) var modelContext
    @Environment(MountFormState.self) private var mountFormState
    @Binding var doConnectionTest: Bool
    @Binding var validationErrors: [Error]
    
    // Actions helper for the logic:
    private var actions: EditorActions {
        EditorActions(modelContext: modelContext, mountFormState: mountFormState)
    }
    
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup{
            self.testConnectionButton()
        }
            
        ToolbarItemGroup {
            
            // 1.) The cancel button:
            self.cancelButton()
            
            // 2.) We are adding a new mount:
            if let mount = self.mountFormState.editing, !mount.exists(context: self.modelContext) {
                self.addButton()
                
            // 3.) Editing an existing mount:
            } else {
                self.saveButton()
                self.deleteButton()
            }
        }
    }
    
    
    // MARK: - Components
    /// Triggers the addition of a new mount.
    private func addButton() -> some View {
        ToolbarButton(
            title: "Add",
            validationErrors: self.$validationErrors
        ) {
            try actions.addMount()
        }
    }
    
    /// Triggers the saving of an existing mount.
    private func saveButton() -> some View {
        // Ensure we have a mount to save:
        guard let mount = self.mountFormState.editing else {
            logger("No mount to save, displaying an empty view.", level: .error)
            return AnyView(EmptyView())
        }
        
        // Confirmation dialog for remounting if connected:
        let dialog = ConfirmationDialogModel(
            title: "Remount Required",
            message: "This mount is currently connected. Would you like to remount it with the new credentials?",
            items: [
                ConfirmationDialogItem(
                    label: "Remount with New Credentials",
                   validationErrors: self.$validationErrors
                ) {
                    try await self.actions.saveWithRemount()
                },
                ConfirmationDialogItem(
                    label: "Save Without Remounting",
                    validationErrors: self.$validationErrors
                ) {
                    try self.actions.saveMount()
                }
            ]
        )
        
        return AnyView(
            ToolbarButton(
                title: "Save",
                // On save, if the mount is connected, show remount confirmation:
                dialog: mount.status == .connected ? dialog : nil,
                validationErrors: self.$validationErrors
            ) {
                try actions.saveMount()
            }
        )
    }
    
    /// Triggers the deletion of the current mount.
    private func deleteButton() -> some View {
        // Ensure we have a mount to save:
        guard let mount = self.mountFormState.editing else {
            return AnyView(EmptyView())
        }
        
        // Confirmation dialog for unmounting if connected:
        let dialog = ConfirmationDialogModel(
            title: "Unmount Required",
            message: "This mount is currently connected. It will be unmounted before deletion.",
            items: [
                ConfirmationDialogItem(
                    label: "Unmount and Delete",
                    validationErrors: self.$validationErrors
                ) {
                    try await self.actions.deleteWithUnmount()
                },
                ConfirmationDialogItem(
                    label: "Delete Without Unmounting",
                    validationErrors: self.$validationErrors
                ) {
                    try self.actions.deleteMount()
                }
            ]
        )
        
        return AnyView(
            ToolbarButton(
                title: "Delete",
                // On delete, if the mount is connected, show unmount confirmation:
                dialog: mount.status == .connected ? dialog : nil,
                validationErrors: self.$validationErrors
            ) {
                try self.actions.deleteMount()
            }
        )
    }
    
    /// Button to cancel the current operation and close the editor.
    private func cancelButton() -> some View {
        ToolbarButton(
            title: "Cancel",
            color: Config.UI.Colors.secondary
        ) {
            self.actions.cancelEditing()
            self.validationErrors.removeAll()
        }
    }

    /// Button to test the connection to the mount.
    private func testConnectionButton() -> some View {
        ToolbarButton(
            title: "Test Connection",
            color: Config.UI.Colors.secondary,
            validationErrors: self.$validationErrors
        ) {
            guard let mount = self.mountFormState.formData else { return }
            try self.actions.validateMount(mount)
            self.doConnectionTest = true
        }
    }
}
