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
    enum Ports {
        nonisolated static let samba: Int = 445
    }
}
