//
//  TextFieldStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/20/25.
//

import SwiftUI

struct TextFieldStyle: ViewModifier {
    
    // MARK: - Properties
    let padding: CGFloat = Config.UI.Layout.padding
    let corner_radius: CGFloat = Config.UI.Layout.borderCornerRadius
    let background_color: Color = Config.UI.Colors.fieldsBackground
    let field_max_width: CGFloat = Config.UI.Layout.fieldsMaxWidth
    var is_grouped: Bool = false
    
    
    // MARK: - Initializer
    init(is_grouped: Bool? = nil) { self.is_grouped = is_grouped ?? self.is_grouped }
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(self.padding)
            .background(
                // If we're grouping fields, remove the radius:
                is_grouped ?
                AnyView(self.background_color) :
                AnyView(
                    RoundedRectangle(cornerRadius: corner_radius)
                        .fill(background_color)
                )
            )
    }
}
