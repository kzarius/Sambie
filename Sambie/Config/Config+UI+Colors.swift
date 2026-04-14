//
//  Config+UI+Colors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//


import SwiftUI

/// Colors for UI elements configuration.
extension Config.UI {
    enum Colors {
        static let primary = Color.purple
        static let secondary = Color.gray
        static let text = Color.white
        static let utility = Color.teal
        static let border = Config.UI.Colors.secondary.opacity(0.6)
        static let buttonBackground = Config.UI.Colors.primary
        static let fieldsBackground = Config.UI.Colors.secondary.opacity(0.1)
        
        static let error = Color.red
        static let warning = Color.yellow
        static let success = Color.teal
        static let unused = Color.gray
        
        enum List {
            static let disconnected = Config.UI.Colors.secondary.opacity(0.1)
            static let connecting = Config.UI.Colors.primary.opacity(0.2)
            static let connected = Config.UI.Colors.primary.opacity(0.5)
            static let error = Config.UI.Colors.error.opacity(0.5)
        }
    }
}
