//
//  Host.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 18/3/2026.
//

import SwiftData
import SwiftUI


@Model
final class Host {

    // MARK: - Properties
    var id: UUID                    // Unique identifier.
    var hostname: String            // The hostname or IP address of the server.
    var port: Int                   // The SMB port for this host. Default is 445.
    var order: Int                  // Display order in the grouped list.
    var paletteName: String         // Color palette name for UI theming.
    var customDisplayName: String?  // Optional user-defined alias (e.g. "Home NAS").

    // Relationship — deny deletion if mounts still exist:
    @Relationship(deleteRule: .deny, inverse: \Mount.host)
    var mounts: [Mount] = []


    // MARK: - Initializer
    init(
        id: UUID? = nil,
        hostname: String = "server.local",
        port: Int = Config.Ports.samba,
        order: Int = 0,
        displayName: String? = nil
    ) {
        self.id = id ?? UUID()
        self.hostname = hostname
        self.port = port
        self.order = order
        self.customDisplayName = displayName
        self.paletteName = Config.UI.Colors.Palette.allCases.randomElement()?.rawValue
                    ?? Config.UI.Colors.Palette.orangish.rawValue
    }


    // MARK: - Computed
    /// The name to show in the UI — alias if set, otherwise the raw hostname.
    var displayName: String {
        self.customDisplayName ?? self.hostname
    }
    
    /// Creates a `HostDataObject` from the current `Host` instance.
    func toDataObject() -> HostDataObject {
        HostDataObject(
            persistentID: self.persistentModelID,
            id: self.id,
            hostname: self.hostname,
            port: self.port,
            order: self.order,
            displayName: self.displayName,
            paletteName: self.paletteName
        )
    }
}
