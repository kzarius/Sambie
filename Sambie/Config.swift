//
//  Config.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI

/// Application configuration and constants.
enum Config: Sendable {
    // MARK: - General Configuration
    static let debug = true
    
    // MARK: - Paths and Identifiers
    enum Paths {
        static let serviceName = "com.kaeomc.sambie"
        static let dbPath = "sambie.sqlite"
        static let keychainService = "com.sambie.mounts"
        static let sambaMountBase = "/Volumes"
    }
    
    enum Ports {
        nonisolated static let samba: Int = 445
    }
    
    // MARK: - UI Configuration
    enum UI {
        enum Icons {
            static let menuBar = "externaldrive.fill"
            static let dismiss = "xmark.circle.fill"
            
            enum List {
                static let drive = "externaldrive.fill"
                static let add = "plus.circle.fill"
                static let edit = "pencil.circle.fill"
                static let openMount = "eye.circle.fill"
                static let error = "exclamationmark.bubble.fill"
                static let loading = "gearshape.fill"
            }
            
            enum Editor {
                static let save = "checkmark.circle.fill"
                static let delete = "minus.circle.fill"
                static let add = "plus.circle.fill"
                static let checkConnection = "network"
                static let ok = "checkmark.circle.fill"
                static let error = "exclamationmark.circle.fill"
            }
        }
        
        // Measurements and constants for UI elements:
        enum Layout {
            static let padding: CGFloat = 6
            static let horizontalPadding: CGFloat = 20
            static let fieldsMaxWidth: CGFloat = 200.0
            static let borderCornerRadius: CGFloat = 6
            static let borderWidth: CGFloat = 1
        }
        
        // Colors for UI elements:
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
    
    enum Connection {
        // Interval for checking if a mount is still connected:
        nonisolated static let checkMountInterval = 10.0
    }
}
