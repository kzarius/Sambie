//
//  Modal.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 9/11/25.
//

import SwiftUI

struct ConfirmationModal<Content: View>: View {
    
    // MARK: - Properties
    // States:
    @Binding var is_active: Bool
    
    // Local:
    let content: () -> Content
    let padding = 30.0
    let max_width = 400.0
    let corner_radius = 12.0
    
    
    // MARK: - View
    var body: some View {
        if self.is_active {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    self.is_active = false
                }
                .overlay {
                    self.content()
                        .padding(self.padding)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(self.corner_radius)
                        .shadow(radius: 20)
                        .frame(maxWidth: self.max_width)
                }
        }
    }
}
