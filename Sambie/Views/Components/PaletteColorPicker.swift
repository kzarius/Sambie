//
//  PaletteColorPicker.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//

import SwiftUI

struct PaletteColorPicker: View {

    @Binding var selectedColor: Color
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Config.UI.Colors.Palette.allCases) { paletteColor in
                Circle()
                    .fill(paletteColor.color)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if paletteColor.color == self.selectedColor {
                            Circle().strokeBorder(.white, lineWidth: 2)
                        }
                    }
                    .onTapGesture {
                        self.selectedColor = paletteColor.color
                        self.onSelect?()
                    }
            }
        }
        .padding(10)
    }
}
