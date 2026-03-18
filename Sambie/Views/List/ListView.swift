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
    
    // Group mounts by host:
    private var groupedMounts: [(host: String, mounts: [Mount])] {
        let grouped = Dictionary(grouping: savedMounts, by: { $0.host?.hostname ?? "Unknown" })
        return grouped.map { hostname, mounts in
            (host: hostname, mounts: mounts)
        }
        .sorted { $0.host < $1.host }
    }

    
    // MARK: - View
    var body: some View {
        List {
            ForEach(groupedMounts, id: \.host) { group in
                self.hostHeaderRow(for: group.host)
                self.shareRows(for: group)
            }
            
            AddMountRow(editorState: self.$editorState)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentSize.height
        } action: { _, newHeight in
            contentHeight = newHeight
        }
        .onChange(of: self.savedMounts.count) {
            contentHeight = 0
        }
        .navigationTitle("Mounts")
        .listStyle(.plain)
        .frame(width: 620)
        .frame(height: min(contentHeight, 620))
    }
    
    
    // MARK: - Subviews
    @ViewBuilder
    private func hostHeaderRow(for host: String) -> some View {
        HStack {
            Image(systemName: "server.rack")
                .foregroundStyle(.secondary)
            Text(host)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func shareRows(for group: (host: String, mounts: [Mount])) -> some View {
        ForEach(group.mounts) { mount in
            shareRow(for: mount)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
        }
    }

    @ViewBuilder
    private func shareRow(for mount: Mount) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 16)

            ListRow(
                mount: mount,
                editorState: self.$editorState
            )
        }
    }

    @ViewBuilder
    private func realMountRow(mount: Mount) -> some View {
        ListRow(
            mount: mount,
            editorState: self.$editorState
        )
    }

    @ViewBuilder
    private func fakeMountRow(name: String) -> some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)
            Text(name)
                .foregroundStyle(.secondary)
                .italic()
            Spacer()
            Text("mock")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
        .font(.title2)
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
