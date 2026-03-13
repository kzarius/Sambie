//
//  SettingsFormBlock.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 12/3/2026.
//

import SwiftUI

struct SettingsFormBlock<Content: View>: View {

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
            fontSize: .headline,
            spacing: 12
        ) {
            self.content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
