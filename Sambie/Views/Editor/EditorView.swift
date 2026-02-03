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
    // It might seem redundant but we need mountID because @Query cannot accept a Binding directly, it needs to be set up in init:
    let mountID: PersistentIdentifier
    @Query private var mounts: [Mount]
    
    // States and bindings:
    @Binding var editingMountID: PersistentIdentifier?
    @State private var doConnectionTest: Bool = false
    @State private var validationErrors: [Error] = []
    // We store sambaURL here to pass to child views:
    @State private var sambaURL: String = ""
    // The shared form data for the mount being edited:
    @State private var formData: MountDataObject?
    // Password field state (not stored in formData for security):
    @State private var password: String = ""
    
    private var editingMount: Mount? { self.mounts.first }
    
    
    // MARK: - Initializer
    init(mountID: PersistentIdentifier, editingMountID: Binding<PersistentIdentifier?>) {
        self.mountID = mountID
        self._editingMountID = editingMountID

        // Configure the @Query to fetch the specific mount by its ID:
        let predicate = #Predicate<Mount> { $0.persistentModelID == mountID }
        _mounts = Query(filter: predicate)
    }
    
    
    // MARK: - View
    var body: some View {
        // Ensure we have both the original mount and the form data to edit:
        if let editingMount = self.editingMount, let formData = self.formData {
            VStack(alignment: .leading, spacing: 0) {
                EditorForm(
                    formData: $formData,
                    password: self.$password,
                    doConnectionTest: self.$doConnectionTest,
                    validationErrors: self.$validationErrors,
                    sambaURL: self.$sambaURL
                )
            }
            .toolbar {
                // Action buttons:
                EditorToolbar(
                    editingMount: editingMount,
                    formData: Binding(
                        get: { formData },
                        set: { self.formData = $0 }
                    ),
                    password: self.$password,
                    editingMountID: self.$editingMountID,
                    doConnectionTest: self.$doConnectionTest,
                    validationErrors: self.$validationErrors
                )
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
            .onAppear {
                self.sambaURL = SambaURL.create(from: formData).absoluteString
            }
        } else {
            ProgressView()
            .onAppear {
                // When the view appears, create the temporary data object from the real mount:
                Task {
                    if let mount = self.editingMount {
                        self.formData = await mount.toDataObject()
                    }
                }
            }
        }
    }
}
