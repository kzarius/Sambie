//
//  EditorForm.swift
//  Sambie
//
//  An editor form for adding or editing a mount. This form includes fields for the mount's display name and credentials, as well as a section for testing the connection. It's a component of the EditorView and is designed to work alongside the EditorToolbar for saving or deleting mounts.
//
//  Created by Kaeo McKeague-Clark on 6/5/25.
//

import SwiftData
import SwiftUI

struct EditorForm: View {
    
    // MARK: - Properties
    // Bound variables:
    @Bindable var actions: EditorActions
    
    // Constants for layout:
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    
    
    // MARK: - View
    /// The main form view for editing or adding a mount.
    var body: some View {
        Form {
            VStack(spacing: 26) {
                
                // If there was an error, show it:
                if !self.actions.validationErrors.isEmpty {
                    EditorErrorPopup(validationErrors: self.$actions.validationErrors)
                }
                
                // Default blocks that will always need rendering:
                self.standardBlocksView
            }
        }
        .padding(20)
    }
    
    var standardBlocksView: some View {
        Group {
            // Profile name:
            EditorFormBlock(
                label: "Display Name",
                icon: "person.fill"
            ) {
                TextField("", text: Binding(
                    get: { self.actions.formData?.name ?? "" },
                    set: { self.actions.formData?.name = $0 }
                ))
                    .modifier(LargeTextFieldStyle())
            }
            
            // Samba URL field:
            EditorFormBlock(
                label: "URL",
                icon: "link"
            ) {
                SambaURLParserField(
                    urlString: self.$actions.sambaURL,
                    validationErrors: self.$actions.validationErrors,
                    formData: self.$actions.formData
                )
            }
            
            // Detailed Connection fields:
            EditorFormBlock(
                label: "Detailed",
                icon: "apple.terminal.fill"
            ) {
                CredentialsForm(
                    formData: self.$actions.formData,
                    password: self.$actions.password
                )
            }
        }
    }
}
