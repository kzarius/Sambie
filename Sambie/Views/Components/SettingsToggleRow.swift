//
//  SettingsToggleRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 6/3/2026.
//

import SwiftUI

/// Describes the on and off states of a settings toggle.
struct ToggleDescription {
    let on: String
    let off: String
}

/// A reusable row view for settings that includes a toggle and descriptive text.
struct SettingsToggleRow: View {
    let title: String
    let description: ToggleDescription
    @Binding var isOn: Bool

    // Convenience: call with `description: (on: "…", off: "…")`
    init(title: String, description: (on: String, off: String), isOn: Binding<Bool>) {
        self.title = title
        self.description = ToggleDescription(on: description.on, off: description.off)
        self._isOn = isOn
    }

    // Original synthesized initializer kept explicitly
    init(title: String, description: ToggleDescription, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }

    private var currentDescription: String { isOn ? description.on : description.off }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Config.UI.Colors.utility))
                .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)

                Text(currentDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
