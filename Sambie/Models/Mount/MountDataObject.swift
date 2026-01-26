//
//  MountDataObject.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 8/1/2026.
//

import SwiftData
import Foundation

/// A data object representing a mount's configuration. Necessary for isolating mount data from SwiftData models.
struct MountDataObject: Sendable, Identifiable {
    var persistentID: PersistentIdentifier
    var id: UUID = UUID()
    // Used for logic during the editing process:
    var isNew: Bool = false
    var order: Int
    var name: String
    var user: String
    var password: String
    var host: String
    var port: Int
    var share: String
}
