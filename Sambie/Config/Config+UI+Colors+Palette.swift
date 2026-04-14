//
//  Config+UI+Colors+Palette.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//

import SwiftUI

extension Config.UI.Colors {
    enum Palette: String, CaseIterable, Identifiable {
        case orangish = "FFA955"
        case cyan = "6DE1D2"
        case purplish = "7C4585"
        case darkPurplish = "3D365C"
        case lightGreen = "BBC863"
        case darkGreen = "31694E"
        case yellowGreen = "F0E491"
        case yellowish = "FFD63A"
        case lightNavy = "547792"
        case navy = "1A3263"
        
        var id: String { self.rawValue }

        var color: Color {
            Color(hex: self.rawValue)
        }
        
        static func from(color: Color) -> Palette? {
            Palette.allCases.first { $0.color == color }
        }
    }
}
