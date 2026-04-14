//
//  ListRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI
import SwiftData

struct ListRow: View {
    
    // MARK: - Properties
    // Passed:
    let mount: Mount
    let isLast: Bool
    
    @Binding var editorState: EditorState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager
    @State private var controller: ListRowController?
    
    // Rounded corners only on the bottom for the last row, none for middle rows:
    private var corners: UnevenRoundedRectangle {
        self.isLast
            ? UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 6,
                topTrailingRadius: 0
            )
            : UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
    }

    
    // MARK: - View
    var body: some View {
        ZStack {
            Color.clear
                .task {
                    // Fetch the accessor from the environment:
                    guard let accessor else {
                        fatalError("MountAccessor not found in environment.")
                    }
                    
                    let vm = ListRowController(
                        mount: self.mount,
                        stateManager: self.stateManager,
                        accessor: accessor
                    )
                    await vm.initialize()
                    self.controller = vm
                }

            if let controller {
                self.rowContent(controller: controller)
            }
        }
    }
    
    @ViewBuilder
    private func rowContent(controller: ListRowController) -> some View {
        ZStack {
            HStack {
                ListRowContent(mount: controller.mount)

                HStack(spacing: 8) {
                    if controller.transientState.status == .connected {
                        OpenInFinderButton(mountPoint: controller.mountPoint)
                    }

                    EditMountButton {
                        self.editorState = controller.editMount()
                    }
                }
                .padding(.trailing, 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task { await controller.handleMountToggle() }
            }
        }
        .overlay(alignment: .center) {
            if !controller.transientState.errors.isEmpty {
                ListErrorPopup(
                    errors: controller.transientState.errors,
                    onDismiss: {
                        Task { await controller.dismissError() }
                    }
                )
            }
        }
        .padding(8)
        .background(
            ZombieBackground(
                isZombie: controller.transientState.isZombie,
                staticBackground: controller.backgroundColour
            )
        )
        .clipShape(self.corners)
        .font(.title2)
        .listRowSeparator(.hidden)
        .onChange(of: controller.transientState.status) {
            Task { await controller.fetchMountPoint() }
        }
    }
}
