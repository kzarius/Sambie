//
//  MenubarIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

struct MenuBarIcon: View {
    
    // MARK: - Properties
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager
    @State private var mountIDs: [PersistentIdentifier] = []
    
    // Colors:
    private let checkmarkColor = Config.UI.Colors.primary
    private let notConnectedColor = Config.UI.Colors.secondary
    
    // Runs a query to see if there are any connected mounts:
    private var hasConnectedMounts: Bool {
        let connectedStatuses: Set<ConnectionStatus> = [.connected, .disconnecting]
        return self.mountIDs.contains { (mountID: PersistentIdentifier) -> Bool in
            let status = self.stateManager.getState(for: mountID).status
            return connectedStatuses.contains(status)
        }
    }
    

    // MARK: - View
    var body: some View {
        Group {
            // Connected mounts icon:
            if self.hasConnectedMounts {
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(self.checkmarkColor, .primary)
                // Default icon:
            } else {
                Image(systemName: Config.UI.Icons.menuBar)
                    .foregroundColor(self.notConnectedColor)
            }
        }
        .task {
            guard let accessor = self.accessor else { return }
            self.mountIDs = await accessor.getAllMountIDs()
        }
    }
}
