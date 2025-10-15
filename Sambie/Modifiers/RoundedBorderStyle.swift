//
//  RoundedBorderStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/20/25.
//

import SwiftUI

struct RoundedBorderStyle: ViewModifier {
    
    // MARK: - Properties
    let corner_radius = Config.UI.Layout.borderCornerRadius
    let border_color = Config.UI.Colors.border
    let border_width = Config.UI.Layout.borderWidth
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
//            .overlay(RoundedRectangle(cornerRadius: corner_radius)
//                    .stroke(border_color, lineWidth: border_width)
//            )
    }
}
