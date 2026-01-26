//
//  MountListStatusIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/23/25.
//

import SwiftData
import SwiftUI

/// This view displays the status icon for a mount in the list view.
/// It shows a loading icon when connecting or disconnecting,
struct ListStatusIcon: View {
    
    // MARK: - Properties
    let mountID: PersistentIdentifier
    @Environment(MountStateManager.self) private var stateManager
    
    // Details for the icon placement and style:
    let details = (
        x: 10,
        y: -10,
        font: Font.caption
    )
    
    // Necessary to animate the rotation:
    @State private var isRotating = false

    
    // MARK: - Initializers
    var body: some View {
        let state = self.stateManager.getState(for: self.mountID)
        
        ZStack {
            
            Image(systemName: Config.UI.Icons.List.drive)
                .foregroundStyle(Config.UI.Colors.secondary)

            // Check if we need to show a loading icon:
            if state.status == .connecting || state.status == .disconnecting {
                
                Image(systemName: Config.UI.Icons.List.loading)
                    .foregroundColor(Config.UI.Colors.utility)
                    .font(details.font)
                    .rotationEffect(.degrees(self.isRotating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: self.isRotating
                    )
                    .offset(x: CGFloat(details.x), y: CGFloat(details.y))
                    .onAppear { self.isRotating = true }
                    .onDisappear { self.isRotating = false }
                
            // Check if we should display an error icon:
            } else if !state.errors.isEmpty {
                
                Image(systemName: Config.UI.Icons.List.error)
                    .foregroundStyle(Config.UI.Colors.error)
                    .font(details.font)
                    .offset(x: CGFloat(details.x), y: CGFloat(details.y))
                
            }
            
        }
        
    }
}
