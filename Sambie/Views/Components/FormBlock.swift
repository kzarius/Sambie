//
//  FormBlock.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 12/3/2026.
//

import SwiftUI

struct FormBlock<Content: View>: View {

    // MARK: - Properties
    let label: String
    let icon: String
    let fontSize: Font
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content


    // MARK: - Init
    init(
        label: String,
        icon: String,
        fontSize: Font = .headline,
        spacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.fontSize = fontSize
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }


    // MARK: - View
    var body: some View {
        VStack(alignment: self.alignment, spacing: self.spacing) {
            Label(self.label, systemImage: self.icon)
                .font(self.fontSize)
                .padding(.bottom, 4)

            self.content()
        }
    }
}
