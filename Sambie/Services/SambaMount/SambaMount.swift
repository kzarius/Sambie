//
//  SambaMount.swift
//  Sambie
//
//  Utility to mount SMB shares using SMBClient.
//
//  Created by Kaeo McKeague-Clark on 10/21/25.
//

import SwiftData
import Foundation

/// Utility struct to handle mounting SMB shares using SMBClient.
final actor SambaMount {

    private let accessor: MountAccessor

    init(
        mountID: PersistentIdentifier,
        accessor: MountAccessor
    ) async throws {
        self.accessor = accessor

        // Load configuration (includes host, share, user, etc.):
        guard let mountData = await self.accessor.getData(id: mountID) else {
            throw ClientError.notFound
        }

        // Verify connection prerequisites (keep your existing implementations):
        try await SambaMount.verifyHostResolvable(host: mountData.host)
        try await SambaMount.checkPortAccessible(host: mountData.host, port: mountData.port)
        // Perform the actual NetFS mount:
        try await SambaMount.mountShare(mountData: mountData)

        await logger("Mounted \(mountData.host)/\(mountData.share)", level: .info)
    }
}
