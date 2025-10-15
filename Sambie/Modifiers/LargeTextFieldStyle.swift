//
//  LargeTextFieldStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/24/25.
//

import SwiftUI

struct LargeTextFieldStyle: ViewModifier {
    
    // MARK: - Properties
    let field_max_width: CGFloat = .infinity
    let font: Font = .title2
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .modifier(TextFieldStyle())
            .modifier(RoundedBorderStyle())
            .font(self.font)
            .frame(maxWidth: self.field_max_width)
    }
}
