//
//  ListView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI

struct ListView: View {
    
    // MARK: - Properties
    @Binding var editorState: EditorState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Mount.order) private var allMounts: [Mount]
    // List of only the saved mounts, not including new unsaved ones:
    private var savedMounts: [Mount] {
        self.allMounts.filter { !$0.isTemporary }
    }

    
    // MARK: - View
    var body: some View {
        List {
            // Show the list of mounts:
            ForEach(self.savedMounts) { mount in
                ListRow(
                    mount: mount,
                    editorState: self.$editorState
                )
            }
            .onMove { fromOffsets, toOffset in
                // Update the order of mounts after moving:
                var mounts = self.savedMounts
                mounts.move(fromOffsets: fromOffsets, toOffset: toOffset)
                for (index, mount) in mounts.enumerated() {
                    mount.order = index
                }
                // Save changes to the context:
                try? self.modelContext.save()
            }
            
            // Row to "Add a new mount":
            AddMountRow(editorState: self.$editorState)
        }
        .onAppear {
            logger("ListView appeared with \(self.savedMounts.count) mounts.")
        }
        .navigationTitle("Mounts")
    }
}
