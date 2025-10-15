//
//  EditorToolbar.swift
//  Sambie
//
//  Toolbar for the mount editor view and is a component of the EditorView. Handles actions like adding, saving, deleting mounts, and testing connections. Interacts with the MountEditor service for CRUD operations, and EditorForm for validation feedback.
//
//  Created by Kaeo McKeague-Clark on 6/29/25.
//

import SwiftData
import SwiftUI

struct EditorToolbar: ToolbarContent {
    
    // MARK: - Properties
    @Environment(\.modelContext) var modelContext
    
    @Binding var mount: Mount?
    @Binding var doConnectionTest: Bool
    
    
    // MARK: - Body
    var body: some ToolbarContent {
        ToolbarItemGroup{
            self.testConnectionButton()
        }
            
        ToolbarItemGroup {
            
            // 1.) The cancel button:
            self.cancelButton()
            
            // 2.) We are adding a new mount:
            if let mount = self.mount, !mount.exists(context: self.modelContext) {
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
        ToolbarButton(title: "Add") {
            Task {
                self.modelContext.insert(self.mount!)
                try self.modelContext.save()
                self.closeEditor()
            }
        }
    }
    
    /// Triggers the saving of an existing mount.
    private func saveButton() -> some View {
        ToolbarButton(title: "Save") {
            Task {
                try self.modelContext.save()
                self.closeEditor()
            }
        }
    }
    
    /// Triggers the deletion of the current mount.
    private func deleteButton() -> some View {
        ToolbarButton(title: "Delete") {
            Task {
                self.modelContext.delete(self.mount!)
                try self.modelContext.save()
                self.closeEditor()
            }
        }
    }
    
    /// Button to cancel the current operation and close the editor.
    private func cancelButton() -> some View {
        ToolbarButton(
            title: "Cancel",
            color: Config.UI.Colors.secondary
        ) {
            self.closeEditor()
        }
    }

    /// Button to test the connection to the mount.
    private func testConnectionButton() -> some View {
        ToolbarButton(
            title: "Test Connection",
            color: Config.UI.Colors.secondary
        ) {
            self.doConnectionTest = true
        }
    }

    /// Closes the editor view by setting the mount to nil, closing the Sheet.
    private func closeEditor() { self.mount = nil }
}
