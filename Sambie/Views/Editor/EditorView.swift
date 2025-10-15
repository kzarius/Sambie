//
//  EditorView.swift
//  Shell Mounts
//
//  An editor view for creating and modifying mount configurations. This view is triggered when a user selects a mount from the list or opts to create a new one.
//
//  Created by Kaeo McKeague-Clark on 3/17/25.
//

import SwiftData
import SwiftUI

struct EditorView: View {
    
    // MARK: - Properties
    // SwiftData properties:
    @Environment(\.modelContext) private var modelContext
    
    // States and bindings:
    @Binding var mountID: PersistentIdentifier?
    @State private var mount: Mount?
    @State private var doConnectionTest: Bool = false
    
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EditorForm(
                mount: self.$mount,
                doConnectionTest: self.$doConnectionTest
            )
        }
        .toolbar {
            // Action buttons:
            EditorToolbar(
                mount: self.$mount,
                doConnectionTest: self.$doConnectionTest
            )
        }
        // Load or create the mount on appear:
        .onAppear {
            // Load the selected mount if we have an ID:
            if let mountID = self.mountID, self.mount == nil {
                // Fetch the mount from the database:
                self.mount = RetrieveMount.getMount(id: mountID, in: self.modelContext.container)
            // Create a new mount if none is selected:
            } else {
                self.mount = Mount()
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
    }
}
