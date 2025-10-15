//
//  ErrorPopup.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/26/25.
//

import SwiftUI

/// A view that displays an error message in a popup style.
/// - Parameters:
/// - `message`: The error message to display.
/// - `onDismiss`: A closure that is called when the popup is dismissed.
struct Popup<Content: View>: View {
    
    // MARK: Properties
    var content: Content
    let onDismiss: () -> Void
    
    var background: Color = Config.UI.Colors.secondary
    var foreground: Color = Config.UI.Colors.text
    let padding: CGFloat = 4
    let corner_radius: CGFloat = 2
    let font: Font = .caption
    
    
    // MARK: Initializer
    /// Initializes a new `Popup` view with an internal view.
    init(
        content: Content,
        onDismiss: @escaping () -> Void,
        background: Color? = nil,
        foreground: Color? = nil
    ) {
        self.content = content
        self.onDismiss = onDismiss
        self.background = background ?? self.background
        self.foreground = foreground ?? self.foreground
    }

    
    // MARK: View Body
    var body: some View {
        HStack {
            
            // Dismiss button:
            Button(action: { onDismiss() }) {
                Image(systemName: Config.UI.Icons.dismiss)
                    .foregroundColor(self.foreground)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Message body:
            self.content
        }
        .font(self.font)
        .padding(self.padding)
        .background(self.background)
        .cornerRadius(self.corner_radius)
        .zIndex(1)
    }
}
