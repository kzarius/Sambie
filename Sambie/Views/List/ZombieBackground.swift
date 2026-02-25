//
//  ZombieBackground.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 25/2/2026.
//

import SwiftUI

struct ZombieBackground: View {

    // MARK: - Properties
    let isZombie: Bool
    let staticBackground: Color

    @State private var pulse = false


    // MARK: - Body
    var body: some View {
        if isZombie {
            ZStack {
                Color(red: 0.28, green: 0.62, blue: 0.22)
                Color(red: 0.10, green: 0.35, blue: 0.10)
                    .opacity(pulse ? 0.7 : 0.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulse
                    )
            }
            .onAppear { pulse = true }
            .onDisappear { pulse = false }
        } else {
            staticBackground
        }
    }
}
