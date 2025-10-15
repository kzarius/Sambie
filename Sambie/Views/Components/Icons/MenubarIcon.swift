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
    @Environment(\.modelContext) private var model_context
    @Query private var mounts: [MountData]
    
    // Colors:
    private let checkmark_color = Config.UI.Colors.primary
    private let not_connected_color = Config.UI.Colors.secondary
    
    // Runs a query to see if there are any connected mounts:
    private var has_connected_mounts: Bool {
        return self.mounts.contains {
            $0.state.status == MountStatus.connected ||
            $0.state.status == MountStatus.disconnecting
        }
    }
    

    // MARK: - View
    var body: some View {
        // Connected mounts icon:
        if self.has_connected_mounts {
            Image(systemName: "externaldrive.fill.badge.checkmark")
                .symbolRenderingMode(.palette)
                .foregroundStyle(self.checkmark_color, .primary)
        // Default icon:
        } else {
            Image(systemName: Config.UI.Icons.menuBar)
                .foregroundColor(self.not_connected_color)
        }
    }
}
