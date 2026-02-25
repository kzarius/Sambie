//
//  ListRowContent.swift
//  Sambie
//
//  Main content button for mount list rows.
//
//  Created by Kaeo McKeague-Clark on [DATE]
//

import SwiftData
import SwiftUI

struct ListRowContent: View {

    // MARK: - Properties
    let mount: Mount
    @Environment(MountStateManager.self) private var stateManager
    @Environment(\.modelContext) private var modelContext
    
    // Helper to read the current transient state for this mount:
    private var transientState: MountStateManager.MountState {
        self.stateManager.getState(for: mount.persistentModelID)
    }

    
    // MARK: - Body
    var body: some View {
        HStack {
            // Status icon:
            ListStatusIcon(mountID: self.mount.persistentModelID)
            
            // Zombie indicator -
            // Shown when mount is connected but server is unreachable:
            if self.transientState.isZombie, let since = self.transientState.serverUnreachableSince {
                ZombieIndicator(since: since)
            }
            
            // Auto-reconnect indicator:
            AutoReconnectButton(mount: self.mount)
            
            Text(self.mount.name)
                .foregroundStyle(Config.UI.Colors.text)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: self.transientState.isZombie)
    }
}
