//
//  MenubarRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

struct MenuBarMountRow: View {
    
    // MARK: - Properties
    // Passed:
    let mount: Mount
    
    // Declared:
    @Environment(\.openWindow) private var openWindow
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager
    @State private var mountConnection: MountClient?
    
    
    // MARK: - View
    var body: some View {
        Button {
            Task {
                let state = self.stateManager.getState(for: self.mount.persistentModelID)
                
                // Open the main window if there's an error:
                if !state.errors.isEmpty {
                    self.openWindow(id: "mounts-window")
                    return
                }
                
                // Otherwise, toggle the mount state:
                await self.toggleMount()
            }
        } label: {
            HStack {
                MenuBarStatusIcon(mountID: self.mount.persistentModelID)
                    
                Text("/\(self.mount.share)")
            }
        }
        // Disable until we have a connection to the mount:
        .disabled(self.mountConnection == nil)
        .task {
            guard let accessor = self.accessor else {
                fatalError("Mount accessor is not available in MenuBarRow.")
            }
            
            self.mountConnection = await MountClient(
                mountID: self.mount.persistentModelID,
                accessor: accessor,
                stateManager: self.stateManager
            )
        }
    }
    
    /// Toggles the mount state between connected and disconnected.
    @MainActor
    private func toggleMount() async {
        if let connection = self.mountConnection {
            switch stateManager.getState(for: self.mount.persistentModelID).status {
            case .connected:
                await connection.unmount()
            case .disconnected:
                await connection.mount()
            default:
                break
            }
        }
    }
}
