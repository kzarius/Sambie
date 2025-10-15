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
    var id: UUID
    var order: Int
    var name: String
    var url: URL
    // Status (not persisted):
    @Transient var status: ConnectionStatus = .disconnected
    
    
    // MARK: - Initializer
    /// Initializes a new mount with default values.
    init() {
        self.id = UUID()
        self.order = 0
        self.name = "Mt. Lonely"
        self.url = URL(string: "smb://server/share")!
    }
    
    /// Initializes a new mount with the specified name, paths, and SSH properties.
    init(
        id: UUID?,
        order: Int = 0,
        name: String,
        url: URL
    ) {
        self.id = id ?? UUID()
        self.order = order
        self.name = name
        self.url = url
    }
}
