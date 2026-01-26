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
    // Declared:
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager

    // Binding for the currently editing mount ID. If it's not nil, it will trigger the editing window.
    @Binding var editingMountID: PersistentIdentifier?
    // Connection to the mount:
    @State private var mountConnection: MountClient?
    
    // Helper to read the current transient state for this mount:
    private var transientState: MountStateManager.MountState {
        self.stateManager.getState(for: mount.persistentModelID)
    }

    
    // MARK: - View
    var body: some View {
        ZStack {
            HStack {
                // Content of the mount entry:
                ListRowContent(mount: self.mount) {
                    await self.handleMountToggle()
                }

                // Open in Finder button:
                if self.transientState.status == .connected {
//                        OpenInFinderButton(mountPoint: self.mount.actualMountPoint)
                }

                // Edit button:
                EditMountButton {
                    self.editMount()
                }
            }
        }
        // Show errors if they occur:
        .overlay(alignment: .center) {
            if !self.transientState.errors.isEmpty {
                ListErrorPopup(
                    errors: self.transientState.errors,
                    onDismiss: {
                        Task {
                            // Remove errors when the popup is dismissed:
                            if let mountConnection = self.mountConnection {
                                await mountConnection.dismissError()
                            }
                        }
                    }
                )
            }
        }
        .padding()
        .background(self.setBackgroundColor())
        .font(.title2)
        .cornerRadius(6)
        .listRowSeparator(.hidden)
        .task {
            await self.initialize()
        }
    }

    
    // MARK: - Methods
    private func handleMountToggle() async {
        switch self.stateManager.getState(for: self.mount.persistentModelID).status {
        case .connected:
            await self.mountConnection?.unmount()
        case .disconnected:
            await self.mountConnection?.mount()
        default:
            break
        }
    }
    
    /// Sets the background color of the entry based on the connection state.
    private func setBackgroundColor() -> Color {
        switch self.stateManager.getState(for: self.mount.persistentModelID).status {
        case .disconnecting:
            return Config.UI.Colors.List.connecting
        case .disconnected:
            return Config.UI.Colors.List.disconnected
        case .connecting:
            return Config.UI.Colors.List.connecting
        case .connected:
            return Config.UI.Colors.List.connected
        }
    }
    
    /// Triggers the editing view.
    private func editMount() {
        // Create the data object for the editor from the live model
        self.editingMountID = self.mount.persistentModelID
    }
    
    /// Creates a MountClient instance with the current mount and makes it available.
    private func initialize() async {
        guard let accessor = self.accessor else {
            fatalError("MountAccessor not found in environment.")
        }
        
        self.mountConnection = await MountClient(
            mountID: self.mount.persistentModelID,
            accessor: accessor,
            stateManager: self.stateManager
        )
    }
}
