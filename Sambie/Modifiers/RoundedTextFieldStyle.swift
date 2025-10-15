//
//  RoundedTextFieldStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/20/25.
//

import SwiftUI

struct RoundedTextFieldStyle: ViewModifier {
    
    // MARK: - Properties
    let padding: CGFloat = Config.UI.Layout.padding
    let corner_radius: CGFloat = Config.UI.Layout.borderCornerRadius
    let background_color: Color = Config.UI.Colors.fieldsBackground
    let field_max_width: CGFloat = Config.UI.Layout.fieldsMaxWidth
    var grouping: Bool = false
    
    
    // MARK: - Initializer
    init(grouping: Bool? = nil) { self.grouping = grouping ?? self.grouping }
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .modifier(TextFieldStyle(is_grouped: true))
            .background(
                RoundedRectangle(cornerRadius: corner_radius)
                    .fill(background_color)
            )
            .modifier(RoundedBorderStyle())
    }
}
