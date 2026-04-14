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
    private let hasConnectionsColor = Config.UI.Colors.primary
    private let noConnectionsColor = Config.UI.Colors.secondary
    
    // Computed:
    private var hasConnectedMount: Bool {
        mountIDs.contains {
            let status = stateManager.getState(for: $0).status
            return status == .connected || status == .disconnecting
        }
    }
    

    // MARK: - View
    var body: some View {
        Group {
            if self.hasConnectedMount {
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(self.hasConnectionsColor, .primary)

            } else {
                Image(systemName: Config.UI.Icons.menuBar)
                    .foregroundColor(self.noConnectionsColor)
            }
        }
        // Update the mount IDs when the view appears:
        .task {
            guard let accessor = self.accessor else { return }
            self.mountIDs = await accessor.getMountIDs().values.flatMap { $0 }
        }
    }
}
