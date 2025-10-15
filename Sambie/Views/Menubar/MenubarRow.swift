//
//  MenubarRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI

struct MenuBarRow: View {
    
    // MARK: - Properties
    // Passed:
    let mount: Mount
    
    // Declared:
    @State private var mountConnection: MountClient?
    @Environment(\.openWindow) private var open_window
    
    
    // MARK: - View
    var body: some View {
        Button(action: {
            // Open the main window if there's an error:
            if self.mount.state.error != nil {
                open_window(id: "mounts-window")
                return
            }
            
            // Otherwise, toggle the mount state:
            self.toggleMount()
        }) {
            HStack {
                MenuBarStatusIcon(state: self.mount.state)
                    
                Text(mount.name)
            }
        }
        // Disable until we have a connection to the mount:
        .disabled(self.mountConnection == nil)
        .task {
            self.mountConnection = await MountClient(with: self.mount.makeSnapshot())
        }
    }
    
    private func toggleMount() {
        Task {
            switch self.mount.state.status {
            case .connected:
                await self.mountConnection?.unmount(self.mount)
            case .disconnected:
                await self.mountConnection?.mount(self.mount)
            default:
                break
            }
        }
    }
}
