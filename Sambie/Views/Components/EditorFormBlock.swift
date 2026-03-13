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


    // MARK: - Init
    init(
        label: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.content = content
    }


    // MARK: - View
    var body: some View {
        FormBlock(
            label: self.label,
            icon: self.icon,
            fontSize: .title2,
            spacing: 8
        ) {
            self.content()
        }
    }
}
