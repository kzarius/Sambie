//
//  ContentView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

struct WindowView: View {
    
    // MARK: - Properties
    @State private var editingMountID: PersistentIdentifier?
    
    // Computed binding to control the sheet's presentation
    private var isEditing: Binding<Bool> {
        Binding(
            get: { self.editingMountID != nil },
            set: { if !$0 { self.editingMountID = nil } }
        )
    }
    
    // MARK: - View
    var body: some View {
        
        ListView(editingMountID: self.$editingMountID)
            .frame(minWidth: 200)
            // Editor Sheet:
            // When editingMountData is not nil, present the EditorView sheet.
            .sheet(isPresented: self.isEditing) {
                // Ensure we have an ID to edit
                if let mountID = self.editingMountID {
                    EditorView(
                        mountID: mountID,
                        editingMountID: self.$editingMountID
                    )
                }
            }
    }
}
