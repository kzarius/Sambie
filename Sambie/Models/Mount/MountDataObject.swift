//
//  MountDataObject.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 8/1/2026.
//

import SwiftData
import Foundation

/// A data object representing a mount's configuration. Necessary for isolating mount data from SwiftData models.
struct MountDataObject: Sendable, Identifiable, Equatable {
    static func == (lhs: MountDataObject, rhs: MountDataObject) -> Bool {
        lhs.persistentID == rhs.persistentID &&
        lhs.name == rhs.name &&
        lhs.user == rhs.user &&
        lhs.host == rhs.host &&
        lhs.port == rhs.port &&
        lhs.share == rhs.share &&
        lhs.isNew == rhs.isNew &&
        lhs.autoReconnect == rhs.autoReconnect
    }
    
    var persistentID: PersistentIdentifier
    var id: UUID = UUID()
    var order: Int
    var name: String
    var user: String
    var host: String
    var port: Int
    var share: String
    var autoReconnect: Bool
    // Object-specific:
    var isNew: Bool = false
}
