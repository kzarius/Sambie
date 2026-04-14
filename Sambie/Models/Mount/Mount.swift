//
//  Mount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI


@Model
final class Mount {
    
    // MARK: - Properties
    var id: UUID        // A unique ID. Needed for the Keychain entries.
    var order: Int      // An integer to define ordering of mounts in the mount list.
    var name: String    // A user-defined name for the mount.
    
    var user: String    // The username to connect with.
    var share: String   // The share name on the server.
    
    @Relationship(deleteRule: .nullify)
    var host: Host?     // The Host group this mount belongs to.
    
    // Reconnection properties:
    var autoReconnect: Bool = false
    var wasUnexpectedlyDisconnected: Bool = false // Whether the mount was unexpectedly disconnected. Used to trigger auto-reconnect attempts.
    
    var lastConnectedAt: Date? = nil // The last time the mount was successfully connected. Used to determine if the server has been unreachable for a long time.
    
    // Flagged mounts are there as newly added mounts, not quite meant to be saved yet. They are used to show the new mount in the list immediately after creation, before the user has hit "Save" in the editor.
    @Transient var isTemporary: Bool = false
    
    
    // MARK: - Initializer
    /// Initializes a new mount with default values.
    init(
        id: UUID? = nil,
        order: Int = 0,
        name: String = "Mt. Lonely",
        user: String = "guest",
        share: String = "share",
        isTemporary: Bool = false
    ) {
        self.id = id ?? UUID()
        self.order = order
        self.name = name
        self.user = user
        self.share = share
        self.isTemporary = isTemporary
    }
    
    /// Creates a `MountDataObject` from the current `Mount` instance.
    /// - Returns: A `MountDataObject` representing the current mount.
    func toDataObject() async -> MountDataObject {
        MountDataObject(
            persistentID: self.persistentModelID,
            id: self.id,
            order: self.order,
            name: self.name,
            user: self.user,
            host: self.host?.toDataObject(),
            pendingHostname: self.host?.hostname ?? "",
            share: self.share,
            autoReconnect: self.autoReconnect
        )
    }
}
