//
//  EditorFormBlock.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/24/25.
//

import SwiftUI

struct EditorFormBlock<Content: View>: View {
    
    // MARK: - Properties
    let label: String
    let icon: String
    let content: () -> Content
    let alignment: HorizontalAlignment = .leading
    let fontSize: Font = .title2

    
    // MARK: - View
    var body: some View {
        VStack(
            alignment: self.alignment,
            spacing: 8
        ) {
            // Block title:
            HStack {
                Image(systemName: self.icon)
                    .font(self.fontSize)
                Text(self.label)
                    .font(self.fontSize)
                    .padding(.bottom, 4)
            }
            
            // Content of the block:
            self.content()
        }
    }
}
