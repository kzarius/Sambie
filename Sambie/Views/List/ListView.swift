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
    @State private var contentHeight: CGFloat = 140
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
            .onMove(perform: self.move)
            
            // Row to "Add a new mount":
            AddMountRow(editorState: self.$editorState)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentSize.height
        } action: { _, newHeight in
            contentHeight = newHeight
        }
        .frame(height: min(contentHeight, 520))
        .onAppear {
            logger("ListView appeared with \(self.savedMounts.count) mounts.")
        }
        .navigationTitle("Mounts")
        .listStyle(.plain)
        .frame(width: 520)
        .frame(height: min(contentHeight, 520))
    }
    
    /// Handles reordering of mounts in the list. Updates the `order` property of each mount based on the new order after moving, and saves changes to the context.
    private func move(from source: IndexSet, to destination: Int) {
        // Update the order of mounts after moving:
        var mounts = self.savedMounts
        mounts.move(fromOffsets: source, toOffset: destination)
        for (index, mount) in mounts.enumerated() {
            mount.order = index
        }
        // Save changes to the context:
        try? self.modelContext.save()
    }
}
