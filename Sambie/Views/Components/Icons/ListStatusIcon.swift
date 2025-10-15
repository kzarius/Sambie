//
//  MountListStatusIcon.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/23/25.
//

import SwiftUI

/// This view displays the status icon for a mount in the list view.
/// It shows a loading icon when connecting or disconnecting,
struct ListStatusIcon: View {
    
    // MARK: - Properties
    let state: MountState
    
    // Details for the icon placement and style:
    let details = (
        x: 10,
        y: -10,
        font: Font.caption
    )
    
    // Necessary to animate the rotation:
    @State private var is_rotating = false

    
    // MARK: - Initializers
    var body: some View {
        
        ZStack {
            
            Image(systemName: Config.UI.Icons.List.drive)
                .foregroundStyle(Config.UI.Colors.secondary)

            // Check if we need to show a loading icon:
            if self.state.status == .connecting || self.state.status == .disconnecting {
                
                Image(systemName: Config.UI.Icons.List.loading)
                    .foregroundColor(Config.UI.Colors.utility)
                    .font(details.font)
                    .rotationEffect(.degrees(is_rotating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: is_rotating
                    )
                    .offset(x: CGFloat(details.x), y: CGFloat(details.y))
                    .onAppear { is_rotating = true }
                    .onDisappear { is_rotating = false }
                
            // Check if we should display an error icon:
            } else if self.state.error != nil {
                
                Image(systemName: Config.UI.Icons.List.error)
                    .foregroundStyle(Config.UI.Colors.error)
                    .font(details.font)
                    .offset(x: CGFloat(details.x), y: CGFloat(details.y))
                
            }
            
        }
        
    }
}
