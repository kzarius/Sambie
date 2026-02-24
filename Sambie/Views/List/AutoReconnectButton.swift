//
//  AutoReconnectButton.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 24/2/2026.
//

import SwiftData
import SwiftUI

struct AutoReconnectButton: View {
    
    // MARK: - Types
    private typealias ButtonAppearance = (icon: String, color: Color, help: String)
    
    
    // MARK: - Properties
    let mount: Mount
    @Environment(\.modelContext) private var modelContext
    private var appearance: ButtonAppearance {
        mount.autoReconnect
            ? (
                icon: "arrow.triangle.2.circlepath.circle.fill",
                color: .blue,
                help: "Auto-reconnect is enabled"
            ) : (
                icon: "arrow.triangle.2.circlepath.circle",
                color: .secondary,
                help: "Auto-reconnect is disabled"
            )
    }
    
    
    // MARK: - Body
    var body: some View {
        Button {
            self.mount.autoReconnect.toggle()
            try? self.modelContext.save()
        } label: {
            Image(systemName: self.appearance.icon)
                .foregroundStyle(self.appearance.color)
                .help(self.appearance.help)
        }
        .buttonStyle(.plain)
    }
}
