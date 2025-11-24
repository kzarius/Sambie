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
    // SwiftData properties:
    @Environment(MountFormState.self) private var mountFormState
    
    // Bound variables:
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
                if self.showConnectionTest {
                    VStack {
                        ConnectionTestView(trigger: self.doConnectionTest)
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
            if let mount = self.mountFormState.formData {
                // Profile name:
                EditorFormBlock(
                    label: "Display Name",
                    icon: "person.fill"
                ) {
                    TextField("", text: Binding(
                        get: { mount.name },
                        set: { mount.name = $0 }
                    ))
                    .modifier(LargeTextFieldStyle())
                }
                
                // Samba URL field:
                EditorFormBlock(
                    label: "URL",
                    icon: "link"
                ) {
                    SambaURLParserField(
                        urlString: $sambaURL,
                        validationErrors: $validationErrors,
                        mount: mount
                    )
                }
                
                // Detailed Connection fields:
                EditorFormBlock(
                    label: "Detailed",
                    icon: "apple.terminal.fill"
                ) {
                    DetailedForm()
                }
            }
        }
    }
    
    /// Validates the Samba URL and updates the mount's properties after the user submits the URL field.
    private func validateAndUpdateURL(for mount: Mount) {
        do {
            // Parse the URL and update the mount:
            let (user, host, share) = try MountShare.parseURL(self.sambaURL)
            mount.user = user ?? ""
            mount.host = host
            mount.share = share
            
            // Clear any previous URL validation errors:
            validationErrors.removeAll { error in
                if let configError = error as? ConfigurationError,
                   case .invalidURL = configError {
                    return true
                }
                return false
            }
        } catch {
            // Only add if not already present:
            if !validationErrors.contains(where: {
                ($0 as? ConfigurationError) != nil
            }) { validationErrors.append(error) }
        }
    }
}
