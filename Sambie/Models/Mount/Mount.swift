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
    var host: String    // The hostname or IP address of the server.
    var port: Int       // The port number to connect to. Default is 445.
    var share: String   // The share name on the server.
    
    
    // MARK: - Initializer
    /// Initializes a new mount with default values.
    init(
        id: UUID? = nil,
        order: Int = 0,
        name: String = "Mt. Lonely",
        user: String = "guest",
        host: String = "server.local",
        port: Int = Config.Ports.samba,
        share: String = "share"
    ) {
        self.id = id ?? UUID()
        self.order = order
        self.name = name
        self.user = user
        self.host = host
        self.port = port
        self.share = share
    }
}
