//
//  RoundedDropdownMenuStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/23/25.
//

import SwiftUI

struct RoundedDropdownMenuStyle: ViewModifier {
    
    // MARK: - Properties
    let horizontal_padding: CGFloat = Config.UI.Layout.horizontalPadding
    let padding: CGFloat = Config.UI.Layout.padding
    let corner_radius: CGFloat = Config.UI.Layout.borderCornerRadius
    let background_color: Color = Config.UI.Colors.primary
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, self.horizontal_padding)
            .padding(.vertical, self.padding)
            .background(
                RoundedRectangle(
                    cornerRadius: self.corner_radius,
                ).fill(self.background_color)
            )
            .contentShape(Rectangle())
    }
}
