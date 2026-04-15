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
        lhs.user == rhs.user &&
        lhs.host == rhs.host &&
        lhs.share == rhs.share &&
        lhs.summary == rhs.summary &&
        lhs.isNew == rhs.isNew &&
        lhs.pendingHostname == rhs.pendingHostname &&
        lhs.autoReconnect == rhs.autoReconnect
    }
    
    var persistentID: PersistentIdentifier
    var id: UUID = UUID()
    var order: Int
    var user: String
    var host: HostDataObject?
    var pendingHostname: String = ""
    var share: String
    var summary: String?
    var autoReconnect: Bool
    // Object-specific:
    var isNew: Bool = false
}
