//
//  EditorView.swift
//  Sambie
//
//  An editor view for creating and modifying mount configurations. This view is triggered when a user selects a mount from the list or opts to create a new one.
//
//  Created by Kaeo McKeague-Clark on 3/17/25.
//

import SwiftData
import SwiftUI

struct EditorView: View {
    
    // MARK: - Properties
    // Environment:
    @Environment(MountFormState.self) private var mountFormState
    // States and bindings:
    @State private var doConnectionTest: Bool = false
    @State private var validationErrors: [Error] = []
    @State private var sambaURL: String = ""
    
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if self.mountFormState.formData != nil {
                EditorForm(
                    doConnectionTest: self.$doConnectionTest,
                    validationErrors: self.$validationErrors,
                    sambaURL: self.$sambaURL
                )
            }
        }
        .toolbar {
            if self.mountFormState.editing != nil {
                // Action buttons:
                EditorToolbar(
                    doConnectionTest: self.$doConnectionTest,
                    validationErrors: self.$validationErrors
                )
            }
        }
        // Handle connection testing:
        .onChange(of: self.doConnectionTest) { old, new in
            if new {
                // Reset after a delay to allow the test to complete:
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.doConnectionTest = false
                }
            }
        }
        // Initialize sambaURL when mount loads:
        .onChange(of: self.mountFormState.formData) { _, newMount in
            if let mount = newMount {
                self.sambaURL = MountShare.buildURL(from: mount)
            }
        }
        .onAppear {
            if let mount = self.mountFormState.formData {
                self.sambaURL = MountShare.buildURL(from: mount)
            }
        }
    }
}
