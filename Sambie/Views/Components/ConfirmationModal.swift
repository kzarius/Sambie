//
//  ConfirmationModal.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 9/11/25.
//

import SwiftUI

struct ConfirmationModal<Content: View>: View {
    
    // MARK: - Properties
    // States:
    @Binding var isActive: Bool
    
    // Local:
    let content: () -> Content
    let padding = 30.0
    let maxWidth = 400.0
    let cornerRadius = 12.0
    
    
    // MARK: - View
    var body: some View {
        if self.isActive {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    self.isActive = false
                }
                .overlay {
                    self.content()
                        .padding(self.padding)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(self.cornerRadius)
                        .shadow(radius: 20)
                        .frame(maxWidth: self.maxWidth)
                }
        }
    }
}
