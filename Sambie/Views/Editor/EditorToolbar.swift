//  EditorToolbar.swift
//  Sambie
//
//  Toolbar for the mount editor view and is a component of the EditorView. Handles actions like adding, saving, deleting mounts, and testing connections.
//
//  Created by Kaeo McKeague-Clark on 6/29/25.
//

import SwiftData
import SwiftUI

struct EditorToolbar: ToolbarContent {
    
    // MARK: - Properties
    @Bindable var actions: EditorActions
    
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup {
            
            // 1.) The cancel button:
            self.cancelButton()
            
            // Unwrap the mount data:
            if self.actions.isNewMount {
                
            // 2.) We are adding a new mount:
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
            validationErrors: self.$actions.validationErrors
        ) {
            try self.actions.addMount()
        }
    }
    
    /// Triggers the saving of an existing mount.
    private func saveButton() -> some View {
        // Confirmation dialog for remounting if connected:
        let dialog = ConfirmationDialogModel(
            title: "Remount Required",
            message: "This mount is currently connected. Would you like to remount it with the new credentials?",
            items: [
                ConfirmationDialogItem(
                    label: "Remount with New Credentials",
                    validationErrors: self.$actions.validationErrors
                ) {
                    try await self.actions.saveWithRemount()
                },
                ConfirmationDialogItem(
                    label: "Save Without Remounting",
                    validationErrors: self.$actions.validationErrors
                ) {
                    Task {
                        try self.actions.saveMount()
                    }
                }
            ]
        )
        
        return ToolbarButton(
            title: "Save",
            // On save, if the mount is connected, show remount confirmation:
            dialog: self.actions.isConnected ? dialog : nil,
            validationErrors: self.$actions.validationErrors
        ) {
            Task {
                try self.actions.saveMount()
            }
        }
    }
    
    /// Triggers the deletion of the current mount.
    private func deleteButton() -> some View {
        // Confirmation dialog for unmounting if connected:
        let dialog = ConfirmationDialogModel(
            title: "Unmount Required",
            message: "This mount is currently connected. It will be unmounted before deletion.",
            items: [
                ConfirmationDialogItem(
                    label: "Unmount and Delete",
                    validationErrors: self.$actions.validationErrors
                ) {
                    try await self.actions.deleteWithUnmount()
                },
                ConfirmationDialogItem(
                    label: "Delete Without Unmounting",
                    validationErrors: self.$actions.validationErrors
                ) {
                    Task {
                        try self.actions.deleteMount()
                    }
                }
            ]
        )
        
        return ToolbarButton(
            title: "Delete",
            // On delete, if the mount is connected, show unmount confirmation:
            dialog: self.actions.isConnected ? dialog : nil,
            validationErrors: self.$actions.validationErrors
        ) {
            Task {
                try self.actions.deleteMount()
            }
        }
    }
    
    /// Button to cancel the current operation and close the editor.
    private func cancelButton() -> some View {
        ToolbarButton(
            title: "Cancel",
            color: Config.UI.Colors.secondary
        ) {
            self.actions.cancelEditing()
            self.actions.validationErrors.removeAll()
        }
    }
}
