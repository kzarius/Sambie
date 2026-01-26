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
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager
    @Environment(\.modelContext) private var modelContext
    
    let editingMount: Mount
    @Binding var formData: MountDataObject
    @Binding var editingMountID: PersistentIdentifier?
    @Binding var doConnectionTest: Bool
    @Binding var validationErrors: [Error]
    
    // Actions helper for the logic:
    private var actions: EditorActions {
        // Ensure we have the accessor:
        guard let accessor = self.accessor else {
            fatalError("MountAccessor not found in environment.")
        }
        
        return EditorActions(
            accessor: accessor,
            stateManager: self.stateManager,
            modelContext: self.modelContext,
            editingMount: self.editingMount,
            editingMountID: self.$editingMountID,
            formData: self.$formData
        )
    }
    
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup{
            self.testConnectionButton()
        }
            
        ToolbarItemGroup {
            
            // 1.) The cancel button:
            self.cancelButton()
            
            // Unwrap the mount data:
            if self.editingMount.isNew(in: self.modelContext) {
                
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
            validationErrors: self.$validationErrors
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
                    validationErrors: self.$validationErrors
                ) {
                    try await self.actions.saveWithRemount()
                },
                ConfirmationDialogItem(
                    label: "Save Without Remounting",
                    validationErrors: self.$validationErrors
                ) {
                    Task {
                        try self.actions.saveMount()
                    }
                }
            ]
        )
        
        let isConnected = self.stateManager.getState(for: editingMount.persistentModelID).status == .connected
        
        return ToolbarButton(
            title: "Save",
            // On save, if the mount is connected, show remount confirmation:
            dialog: isConnected ? dialog : nil,
            validationErrors: self.$validationErrors
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
                    validationErrors: self.$validationErrors
                ) {
                    try await self.actions.deleteWithUnmount()
                },
                ConfirmationDialogItem(
                    label: "Delete Without Unmounting",
                    validationErrors: self.$validationErrors
                ) {
                    Task {
                        try self.actions.deleteMount()
                    }
                }
            ]
        )
            
        let isConnected = self.stateManager.getState(for: self.formData.persistentID).status == .connected
        
        return ToolbarButton(
            title: "Delete",
            // On delete, if the mount is connected, show unmount confirmation:
            dialog: isConnected ? dialog : nil,
            validationErrors: self.$validationErrors
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
            Task {
                self.actions.cancelEditing()
            }
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
            do {
                try self.actions.validateMount()
                self.doConnectionTest = true
            } catch {
                self.validationErrors.append(error)
            }
        }
    }
}
