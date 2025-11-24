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
    @Query private var mounts: [Mount]
    
    // Colors:
    private let checkmarkColor = Config.UI.Colors.primary
    private let notConnectedColor = Config.UI.Colors.secondary
    
    // Runs a query to see if there are any connected mounts:
    private var hasConnectedMounts: Bool {
        return self.mounts.contains {
            $0.status == ConnectionStatus.connected ||
            $0.status == ConnectionStatus.disconnecting
        }
    }
    

    // MARK: - View
    var body: some View {
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
}
