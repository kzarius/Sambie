//
//  HostHeaderRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.

import SwiftUI
import SwiftData

struct HostHeaderRow: View {

    // MARK: - Properties
    let host: Host
    
    @Environment(\.mountAccessor) private var accessor
    @State private var selectedColour: Color = .gray
    @State private var showingPicker = false

    private let headerShape = UnevenRoundedRectangle(
        topLeadingRadius: 8,
        bottomLeadingRadius: 8,
        bottomTrailingRadius: 0,
        topTrailingRadius: 8
    )
    
    private var isLightBackground: Bool {
        self.selectedColour.isLight
    }


    // MARK: - Body
    var body: some View {
        HStack {
            Image(systemName: "server.rack")
            .foregroundStyle(.white.opacity(0.8))
                
            Text(self.host.hostname)
            .font(.headline)
            .foregroundStyle(self.isLightBackground ? .black.opacity(0.7) : .white)
            
            Spacer()
            
            Button {
                self.showingPicker.toggle()
            } label: {
                Image(systemName: "paintpalette")
                .foregroundStyle(.white.opacity(0.7))
                .font(.caption)
            }
            .buttonStyle(.plain)
            .popover(isPresented: self.$showingPicker, arrowEdge: .bottom) {
                PaletteColorPicker(selectedColor: self.$selectedColour)
                .onDisappear {
                    self.showingPicker = false
                    
                    // Update the host's palette with the selected color:
                    Task {
                        guard let palette = Config.UI.Colors.Palette.from(color: self.selectedColour) else { return }
                        try? await self.accessor?.setHostPalette(
                            for: self.host.persistentModelID,
                            palette: palette
                        )
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(self.selectedColour.clipShape(self.headerShape))
        .clipShape(self.headerShape)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .onAppear {
            self.selectedColour = Config.UI.Colors.Palette(rawValue: self.host.paletteName)?.color ?? .gray
        }
    }
}
