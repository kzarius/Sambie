//
//  HostDataObject.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 20/3/2026.
//

import SwiftData
import SwiftUI

/// A data object representing a host's configuration. Necessary for isolating host data from SwiftData models.
struct HostDataObject: Sendable, Identifiable, Equatable {
    var persistentID: PersistentIdentifier
    var id: UUID
    var hostname: String
    var port: Int
    var order: Int
    var displayName: String
    var paletteName: String
    
    /// Resolves the palette name to a SwiftUI Color. Call this on the main thread.
    @MainActor
    var color: Color {
        Config.UI.Colors.Palette(rawValue: self.paletteName)?.color ?? .gray
    }
}
