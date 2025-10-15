//
//  ListRow.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI

struct ListRow: View {
    
    // MARK: - Properties
    // Passed:
    let mount: Mount
    
    // Declared:
    @State private var mountConnection: MountClient?
    @State private var backgroundColor: Color? = nil
    @State private var wasRecentlyEdited = false
    

    // MARK: - View
    var body: some View {
        // If we have a connection to this mount, display it's row:
        if let _ = self.mountConnection {
            ZStack {
                HStack {
                    // Content of the mount entry:
                    self.entryContent()

                    // Open in Finder button:
                    if self.mount.state.status == .connected {
                        self.openMountInFinderButton()
                    }

                    // Edit button:
                    self.editMountButton()
                }
            }
            // Handle the connection state changes, like editing the mount:
            .onChange(of: self.selected_mount_for_editing) { _, edited_mount in
                handleEditorChanges(
                    new_mount_data: edited_mount,
                    connection: self.mountConnection!
                )
            }
            // Show errors if they occur:
            .overlay(
                Group {
                    if self.mount.state.error != nil {
                        ListErrorPopup(
                            message: self.mount.state.error!.localizedDescription,
                            onDismiss: {
                                Task {
                                    await self.mountConnection?.dismissError(for: self.mount)
                                }
                            }
                        )
                    }
                },
                alignment: .center
            )
            .padding()
            .background(setBackgroundColor())
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
    /// This method handles changes to the editor, such as when a mount is edited or removed.
    private func handleEditorChanges(new_mount_data: Mount?, connection: MountClient) {
        guard let new_mount_data = new_mount_data, new_mount_data.persistentModelID == self.mount.persistentModelID else {
            if self.was_recently_edited && new_mount_data == nil {
                Task {
                    await connection.updateSnapshot(self.mount.makeSnapshot())
                }
                self.was_recently_edited = false
            }
            return
        }
        self.was_recently_edited = true
    }

    /// Sets the background color of the entry based on the connection state.
    private func setBackgroundColor() -> Color {
        switch self.mount.state.status {
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
    
    /// Opens the mount directory in Finder.
    private func openMountInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: self.mount.paths.target)])
    }
    
    
    // MARK: - Components
    private func entryContent() -> some View {
        Button(action: {
            Task {
                switch self.mount.state.status {
                case .connected:
                    await self.mountConnection?.unmount(self.mount)
                case .disconnected:
                    await self.mount_connection?.mount(self.mount)
                default:
                    break
                }
            }
        }) {
            HStack {
                ListStatusIcon(state: self.mount.state)
                
                Text(self.mount.name)
                    .foregroundStyle(Config.UI.Colors.text)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func editMountButton() -> some View {
        let icon_name = Config.UI.Icons.List.edit
        let icon_color = Config.UI.Colors.utility
        
        return Button(action: {
            self.selected_mount_for_editing = self.mount
        }) {
            Image(systemName: icon_name)
                .foregroundStyle(icon_color)
                .padding(.trailing, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openMountInFinderButton() -> some View {
        let icon_name = Config.UI.Icons.List.openMount
        let foreground_color = Config.UI.Colors.utility
        
        return Button(action: self.openMountInFinder) {
            Image(systemName: icon_name)
                .foregroundStyle(foreground_color)
                .padding(.trailing, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startConnection() async {
        self.mountConnection = await MountClient(with: self.mount.makeSnapshot())
    }
}
