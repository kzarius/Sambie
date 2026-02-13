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
            
            // Auto-reconnect indicator:
            Button {
                self.mount.autoReconnect.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: self.mount.autoReconnect ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle")
                    .foregroundStyle(self.mount.autoReconnect ? .blue : .secondary)
                    .help(mount.autoReconnect ? "Auto-reconnect is enabled" : "Auto-reconnect is disabled")
            }
            .buttonStyle(.plain)
            
            Text(self.mount.name)
                .foregroundStyle(Config.UI.Colors.text)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
