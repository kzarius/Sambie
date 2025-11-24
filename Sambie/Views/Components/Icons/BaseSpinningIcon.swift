//
//  BaseSpinningIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 7/3/25.
//

import SwiftUI

/// A view that displays a spinning icon.
struct BaseSpinningIcon: View {
    
    // MARK: - Properties
    let name: String
    let color: Color
    var is_spinning: Bool = true
    var offset: CGSize = .zero

    @State private var rotation: Double = 0

    
    // MARK: - View
    var body: some View {
        ZStack {
            Image(systemName: self.name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(self.color)
                .offset(offset)
        }
        .rotationEffect(.degrees(self.rotation))
        .onAppear {
            if self.is_spinning {
                withAnimation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false)
                ) {
                    self.rotation = 360
                }
            }
        }
        .onChange(of: self.is_spinning) { _, spinning in
            if spinning {
                self.rotation = 0
                withAnimation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false)
                ) {
                    self.rotation = 360
                }
            } else {
                self.rotation = 0
            }
        }
    }
}
