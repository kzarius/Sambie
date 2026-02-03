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
    @Binding var formData: MountDataObject?
    @Binding var password: String
    @Binding var doConnectionTest: Bool
    @Binding var validationErrors: [Error]
    @Binding var sambaURL: String
    
    @State private var showConnectionTest: Bool = false
    
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
                if !self.validationErrors.isEmpty {
                    EditorErrorPopup(validationErrors: self.$validationErrors)
                }
                
                // Default blocks that will always need rendering:
                self.standardBlocksView
                
                // Connection test results:
                if self.showConnectionTest, let formData = self.formData {
                    VStack {
                        ConnectionTestView(
                            host: formData.host,
                            trigger: self.doConnectionTest
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // When we're testing the connection, show the view:
            .onChange(of: self.doConnectionTest) { _, newValue in
                if newValue {
                    self.showConnectionTest = true
                }
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
                    get: { self.formData?.name ?? "" },
                    set: { self.formData?.name = $0 }
                ))
                    .modifier(LargeTextFieldStyle())
            }
            
            // Samba URL field:
            EditorFormBlock(
                label: "URL",
                icon: "link"
            ) {
                SambaURLParserField(
                    urlString: self.$sambaURL,
                    validationErrors: self.$validationErrors,
                    formData: self.$formData
                )
            }
            
            // Detailed Connection fields:
            EditorFormBlock(
                label: "Detailed",
                icon: "apple.terminal.fill"
            ) {
                CredentialsForm(
                    formData: self.$formData,
                    password: self.$password
                )
            }
        }
    }
}
