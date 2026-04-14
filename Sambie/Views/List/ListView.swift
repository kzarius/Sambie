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
    @State private var controller: ListController?
    @Environment(\.mountAccessor) private var accessor
    @Environment(\.modelContext) private var modelContext

    
    // MARK: - View
    var body: some View {
        Group {
            if let controller {
                self.listContent(controller: controller)
            }
        }
        .task {
            guard let accessor else { return }
            self.controller = ListController(accessor: accessor)
            await self.controller?.fetchMounts()
        }
        .onChange(of: editorState) { _, newState in
            guard case .closed = newState else { return }
            Task {
                await self.controller?.fetchMounts()
            }
        }
    }
    
    
    // MARK: - Subviews
    @ViewBuilder
    /// View for the list content. Displays the grouped mounts with headers and share rows.
    private func listContent(controller: ListController) -> some View {
        List {
            ForEach(controller.orderedHostIDs, id: \.self) { hostID in
                if let host = self.modelContext.model(for: hostID) as? Host {
                    let mountIDs = controller.allMountIDs[hostID] ?? []
                    
                    VStack(spacing: 0) {
                        self.groupRow(
                            host: host,
                            mountIDs: mountIDs,
                            controller: controller
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }
            .onMove { source, destination in
                Task {
                    await controller.moveGroup(from: source, to: destination)
                }
            }

            AddMountRow(editorState: self.$editorState)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentSize.height
        } action: { _, newHeight in
            self.contentHeight = newHeight
        }
        .navigationTitle("Mounts")
        .listStyle(.plain)
        .frame(width: 620)
        .frame(height: min(self.contentHeight, 620))
    }
    
    @ViewBuilder
    /// Renders a single host group with its header and share rows.
    private func groupRow(
        host: Host,
        mountIDs: [PersistentIdentifier],
        controller: ListController
    ) -> some View {
        VStack(spacing: 0) {
            HostHeaderRow(host: host)
            self.shareRows(mountIDs: mountIDs)
        }
    }

    @ViewBuilder
    /// View for the share rows within a host group. Iterates over the mounts for the host and creates a row for each, hiding separators and adjusting insets for a clean grouped appearance.
    private func shareRows(mountIDs: [PersistentIdentifier]) -> some View {
        ForEach(Array(mountIDs.enumerated()), id: \.element) { index, mountID in
            if let mount = self.modelContext.model(for: mountID) as? Mount {
                let isLast = index == mountIDs.count - 1
                
                self.shareRow(mount: mount, isLast: isLast)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            }
        }
    }

    @ViewBuilder
    /// View for an individual share row. Displays the mount information and includes a vertical separator on the left for visual grouping. The `isLast` parameter can be used to adjust styling if needed (e.g., rounded corners on the last item).
    private func shareRow(mount: Mount, isLast: Bool) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4)
                .padding(.leading, 16)

            ListRow(
                mount: mount,
                isLast: isLast,
                editorState: self.$editorState
            )
        }
    }
}
