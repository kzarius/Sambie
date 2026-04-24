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

        guard let hostData = mountData.host else { throw ClientError.notFound }
        
        // Verify connection prerequisites (host is reachable, port is open):
        try await self.accessor.checkHostPortAccessible(for: hostData)
        
        await logger("\(self.accessor.summarize(id: mountID)) passed host port check. Attempting mount...", level: .info)
        
        // Perform the actual NetFS mount:
        try await SambaMount.mountShare(mountData: mountData)

        await logger("Mounted \(self.accessor.summarize(id: mountID))", level: .info)
    }
}
