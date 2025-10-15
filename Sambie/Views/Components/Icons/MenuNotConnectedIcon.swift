//
//  MenuNotConnectedIcon.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI

struct MenuNotConnectedIcon: View {
    let icon_name = "circle"
    let icon_color = Config.UI.Colors.secondary
    
    var body: some View {
        BaseMenuIcon(
            name: icon_name,
            color: icon_color
        )
    }
}
