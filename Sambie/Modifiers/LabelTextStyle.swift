//
//  LabelTextStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/20/25.
//

import SwiftUI

struct LabelTextStyle: ViewModifier {
    
    // MARK: - Properties
    let text_color: Color = Config.UI.Colors.secondary
    
    var font_style: Font = .caption
    var grouping: Bool = false
    
    
    // MARK: - Initializer
    init(
        font_style: Font? = nil,
        grouping: Bool? = nil
    ) {
        self.font_style = font_style ?? self.font_style
        self.grouping = grouping ?? self.grouping
    }
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .font(self.font_style)
            .foregroundColor(text_color)
    }
}
