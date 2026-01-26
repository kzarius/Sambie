//
//  SambaMount.swift
//  Sambie
//
//  Utility to mount SMB shares using SMBClient.
//
//  Created by Kaeo McKeague-Clark on 10/21/25.
//

import KeychainAccess
import Subprocess
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
        let mountData = try await self.accessor.getData(id: mountID)

        // Verify connection prerequisites (keep your existing implementations):
        try await SambaMount.verifyHostResolvable(host: mountData.host)
        try await SambaMount.checkPortAccessible(host: mountData.host, port: mountData.port)

        // Retrieve password from Keychain:
        let keychain = await Keychain(service: Config.Paths.keychainService)
        // We'll default to an empty password if none is found:
        let password = try await keychain.get(generateKeychainKey(for: mountData.id)) ?? ""

        // Ensure a mount point directory under /Volumes:
        let mountPoint = try SambaMount.validateMountPoint(
            name: mountData.name.isEmpty ? mountData.share : mountData.name
        )

        // Perform the actual mount via `mount_smbfs`:
        try await SambaMount.mountShare(
            host: mountData.host,
            share: mountData.share,
            port: mountData.port,
            username: mountData.user,
            password: password,
            mountPoint: mountPoint
        )

        // Optional logging.
        await logger("Mounted \(mountData.host)/\(mountData.share) at \(mountPoint)", level: .info)
    }
    
    /// Calls `/sbin/mount_smbfs` to create an OS\-level mount of the SMB share.
    static func mountShare(
        host: String,
        share: String,
        port: Int,
        username: String,
        password: String,
        mountPoint: String
    ) async throws {
        // Percent\-encode URL components:
        guard
            let encodedUser = username.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed),
            let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed),
            let encodedShare = share.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else {
            throw ClientError.mountFailed(reason: "Failed to percent-encode SMB URL components.")
        }
        
        // `mount_smbfs` accepts `smb://user:pass@host[:port]/share`:
        let hostPort = port == Config.Ports.samba ? host : "\(host):\(port)"
        let smbURL = "smb://\(encodedUser):\(encodedPassword)@\(hostPort)/\(encodedShare)"
        
        let result = try await run(
            .name("mount_smbfs"),
            arguments: [smbURL, mountPoint],
            output: .string(limit: 4096)
        )
        
        // Check exit status and return error on failure:
        guard result.terminationStatus.isSuccess else {
            throw ClientError.mountFailed(reason: result.stderr)
        }
    }
}
