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
    
    // MARK: - View
    var body: some View {
        NavigationSplitView {
            // Show the list of mounts:
            ListView()
                .frame(minWidth: 200)
        } detail: {
            // Show the editor view if we have a mount to edit:
            if let mountID = self.editingMountID {
                EditorView(mountID: self.$editingMountID)
            }
        }
    }
}


#Preview {
    WindowView()
        .modelContainer(for: Mount.self, inMemory: true)
}
