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
    @Environment(\.modelContext) private var modelContext
    @Environment(MountFormState.self) private var mountFormState
    // Connection to the mount:
    @State private var mountConnection: MountClient?
    // Background color based on connection state:
    @State private var backgroundColor: Color? = nil

    
    // MARK: - View
    var body: some View {
        // If we have a connection to this mount, display it's row:
        if self.mountConnection != nil {
            ZStack {
                HStack {
                    // Content of the mount entry:
                    ListRowContent(mount: mount) {
                        await handleMountToggle()
                    }

                    // Open in Finder button:
                    if self.mount.status == .connected {
                        OpenInFinderButton(mountPoint: mount.actualMountPoint)
                    }

                    // Edit button:
                    EditMountButton(mount: mount) {
                        self.mountFormState.startEditing(mount)
                    }
                }
            }
            // Show errors if they occur:
            .overlay(alignment: .center) {
                if !self.mount.errors.isEmpty {
                    ListErrorPopup(
                        errors: self.mount.errors,
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
            
        // Otherwise, if we don't have a connection yet, show a loading state:
        } else {
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 10)
            }
            // Initialize the connection if it doesn't exist:
            .task { await self.startConnection() }
        }
    }

    
    // MARK: - Methods
    private func handleMountToggle() async {
        switch self.mount.status {
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
        switch self.mount.status {
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
    
    /// Creates a MountClient instance with the current mount and makes it available.
    private func startConnection() async {
        self.mountConnection = await MountClient(
            mountID: self.mount.persistentModelID,
            modelContainer: self.modelContext.container
        )
    }
}
