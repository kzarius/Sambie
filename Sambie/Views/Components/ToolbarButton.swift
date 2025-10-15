//
//  ToolbarButton.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 7/9/25.
//

import SwiftUI

struct ToolbarButton: View {
    
    // MARK: - Properties
    let title: String
    let action: () -> Void
    let color: Color
    
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    
    // MARK: - Initializer
    init(
        title: String,
        color: Color = Config.UI.Colors.primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, padding + horizontalPadding)
                .padding(.vertical, padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
