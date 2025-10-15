//
//  ArrowLoadingIcon.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/3/25.
//

import SwiftUI

/// A spinning arrow.clockwise icon, for loading states.
struct ArrowLoadingIcon: View {
    let color = Config.UI.Colors.secondary

    var body: some View {
        BaseSpinningIcon(
            name: "arrow.trianglehead.clockwise",
            color: self.color,
            offset: CGSize(width: 0, height: -1)
        )
    }
}
