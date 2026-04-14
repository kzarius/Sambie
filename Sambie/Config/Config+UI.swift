//
//  Config+UI.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//

import SwiftUI

/// UI Configuration
extension Config {
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
    }
}
