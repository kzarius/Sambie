//
//  MenuConnectedIcon.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI

struct MenuConnectedIcon: View {
    let icon_name = "circle.fill"
    let icon_color = Config.UI.Colors.primary
    
    var body: some View {
        BaseMenuIcon(
            name: icon_name,
            color: icon_color
        )
    }
}
