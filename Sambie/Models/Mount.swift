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
    
    var user: String   // The username to connect with.
    var host: String   // The hostname or IP address of the server.
    var share: String  // The share name on the server.
    
    var customMountPoint: URL?   // An optional local mount path set by the user.
    var actualMountPoint: URL? = nil // The actual mount point used during mounting.
    // NOTE: Struggled with this being persisted. End thoughts are that with actualMP being persistent, we can pick up where we lost it if app restarts without having to continually do a costly search that could return the wrong mount.
    
    // Want to use @Transient, but it's not observed properly yet:
    var status: ConnectionStatus = ConnectionStatus.disconnected
    var errors: [String] = []
    
    
    // MARK: - Initializer
    /// Initializes a new mount with default values.
    init(
        id: UUID? = nil,
        order: Int = 0,
        name: String = "Mt. Lonely",
        user: String = "guest",
        host: String = "server.local",
        share: String = "share",
        customMountPoint: URL? = nil
    ) {
        self.id = id ?? UUID()
        self.order = order
        self.name = name
        self.user = user
        self.host = host
        self.share = share
        self.customMountPoint = customMountPoint
    }
}
