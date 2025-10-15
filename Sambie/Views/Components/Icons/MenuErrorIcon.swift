//
//  MenuErrorIcon.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI

struct MenuErrorIcon: View {
    let icon_name = "exclamationmark.circle.fill"
    let icon_colors = (Color.white, Config.UI.Colors.error)
    
    var body: some View {
        BaseMenuIcon(
            name: icon_name,
            colors: icon_colors
        )
    }
}
