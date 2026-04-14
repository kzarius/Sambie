//
//  Color+isLight.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 14/4/2026.
//

import SwiftUI

extension Color {
    /// Returns true if this color is light enough to require dark text for legibility.
    /// Uses the W3C relative luminance formula.
    var isLight: Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.5
    }
}
