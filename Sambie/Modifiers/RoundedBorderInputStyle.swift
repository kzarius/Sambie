//
//  RoundedBorderInputStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/20/25.
//

import SwiftUI

struct RoundedInputStyle: ViewModifier {
    
    // MARK: - Properties
    let padding = Config.UI.Layout.padding
    let corner_radius = Config.UI.Layout.borderCornerRadius
    let background_color = Config.UI.Colors.fieldsBackground
    let field_max_width = Config.UI.Layout.fieldsMaxWidth
    let border_width = Config.UI.Layout.borderWidth
    
    var grouping: Bool = false
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(self.padding)
            .background(
                RoundedRectangle(cornerRadius: grouping ? 0 : corner_radius)
                    .fill(background_color)
            )
            .modifier(RoundedBorderStyle())
            .frame(maxWidth: field_max_width)
    }
}
