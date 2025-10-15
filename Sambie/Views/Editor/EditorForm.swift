//
//  EditorForm.swift
//  Shell Mounts
//
//  An editor form for adding or editing a mount. This form includes fields for the mount's display name, paths, and SSH properties, as well as a section for testing the connection. It's a component of the EditorView and is designed to work alongside the EditorToolbar for saving or deleting mounts.
//
//  Created by Kaeo McKeague-Clark on 6/5/25.
//

import SwiftData
import SwiftUI

struct EditorForm: View {
    
    // MARK: - Properties
    // SwiftData properties:
    @Environment(\.modelContext) private var model_context
    
    // Bound variables:
    @Binding var form_data: FormData
    @Binding var do_connection_test: Bool
    @Binding var validation_errors: [Error]
    @State private var show_connection_test: Bool = false
    
    
    // MARK: - View
    /// The main form view for editing or adding a mount.
    var body: some View {
        Form {
            VStack(spacing: 26) {
                
                // If there was an error, show it:
                if !self.validation_errors.isEmpty {
                    EditorErrorPopup(validation_errors: self.$validation_errors)
                }
                
                // Default blocks that will always need rendering:
                self.standardBlocksView
                
                // Connection test results:
                if self.show_connection_test {
                    VStack {
                        ConnectionTestView(
                            mount: self.form_data.mount,
                            trigger: self.do_connection_test
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // When we're testing the connection, show the view:
            .onChange(of: self.do_connection_test) { _, new_value in
                if new_value {
                    self.show_connection_test = true
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
                    get: { self.form_data.mount.name },
                    set: { self.form_data.mount.name = $0 }
                ))
                .modifier(LargeTextFieldStyle())
            }
            
            // Paths fields:
            EditorFormBlock(
                label: "Paths",
                icon: "figure.hiking"
            ) {
                PathsForm(paths: Binding(
                    get: { self.form_data.mount.paths },
                    set: { self.form_data.mount.paths = $0 }
                ))
            }
            
            // SSH properties fields:
            EditorFormBlock(
                label: "SSH",
                icon: "personalhotspot"
            ) {
                SSHForm(form_data: Binding(
                    get: { self.form_data },
                    set: { self.form_data = $0 }
                ))
            }
        }
    }
}
