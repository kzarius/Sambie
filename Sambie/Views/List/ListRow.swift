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

    @Binding var editorState: EditorState
    // Connection to the mount:
    @State private var mountConnection: MountClient?
    // The actual mount point URL once connected (used for the "Open in Finder" button):
    @State private var mountPoint: URL? = nil
    
    // Helper to read the current transient state for this mount:
    private var transientState: MountStateManager.MountState {
        self.stateManager.getState(for: mount.persistentModelID)
    }

    
    // MARK: - View
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Drag handle area (fixed width, only this is draggable):
                HStack {
                    Image(systemName: "line.horizontal.3")
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 8)
                }
                .frame(width: 40)
                
                HStack {
                    
                    // Content of the mount entry:
                    ListRowContent(mount: self.mount)
                    
                    HStack(spacing: 8) {
                        
                        // Open in Finder button:
                        if self.transientState.status == .connected {
                            OpenInFinderButton(mountPoint: self.mountPoint)
                        }
                        
                        // Edit button:
                        EditMountButton {
                            self.editMount()
                        }
                    }
                    .padding(.trailing, 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task {
                        await self.handleMountToggle()
                    }
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
        .padding(8)
        .background(
            ZombieBackground(
                isZombie: transientState.isZombie,
                staticBackground: self.setBackgroundColor()
            )
        )
        .font(.title2)
        .cornerRadius(6)
        .listRowSeparator(.hidden)
        // Initialize the mount connection when the view appears:
        .task {
            await self.initialize()
        }
        // Fetch the mount point whenever the connection status changes:
        .onChange(of: self.transientState.status) {
            Task { await self.fetchMountPoint() }
        }
    }

    
    // MARK: - Methods
    private func handleMountToggle() async {
        switch self.stateManager.getState(for: self.mount.persistentModelID).status {
            
        // Disconnect:
        case .connected:
            self.mount.autoReconnect = false
            await self.mountConnection?.unmount()
            
        // Connect:
        case .disconnected:
            await self.mountConnection?.mount()
            
        // Cancel:
        case .connecting:
            await self.mountConnection?.cancel()
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
        self.editorState = .editing(self.mount.persistentModelID)
    }
    
    /// Fetches the mount point for the current mount if it is connected.
    private func fetchMountPoint() async {
        // Only attempt to fetch the mount point if we're currently connected:
        guard self.transientState.status == .connected else {
            self.mountPoint = nil
            return
        }
        
        // Fetch the mount path from the SambaMount utility:
        if let path = try? await SambaMount.getMountPath(
            user: self.mount.user,
            host: self.mount.host,
            share: self.mount.share
        ) {
            self.mountPoint = URL(filePath: path)
        } else {
            self.mountPoint = nil
        }
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
