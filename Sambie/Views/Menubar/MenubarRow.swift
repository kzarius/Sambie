//
//  MenubarRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

struct MenuBarRow: View {
    
    // MARK: - Properties
    // Passed:
    let mount: Mount
    
    // Declared:
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @State private var mountConnection: MountClient?
    
    
    // MARK: - View
    var body: some View {
        Button(action: {
            // Open the main window if there's an error:
            if !self.mount.errors.isEmpty {
                openWindow(id: "mounts-window")
                return
            }
            
            // Otherwise, toggle the mount state:
            self.toggleMount()
        }) {
            HStack {
                MenuBarStatusIcon(
                    status: self.mount.status,
                    errors: self.mount.errors
                )
                    
                Text(mount.name)
            }
        }
        // Disable until we have a connection to the mount:
        .disabled(self.mountConnection == nil)
        .task {
            self.mountConnection = await MountClient(mountID: self.mount.persistentModelID, modelContainer: self.modelContext.container)
        }
    }
    
    private func toggleMount() {
        Task {
            if let mountConnection {
                switch self.mount.status {
                case .connected:
                    await mountConnection.unmount()
                case .disconnected:
                    await mountConnection.mount()
                default:
                    break
                }
            }
        }
    }
}
