//
//  SettingsToggleRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 6/3/2026.
//

import SwiftUI

/// A reusable row view for settings that includes a toggle and descriptive text.
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}
