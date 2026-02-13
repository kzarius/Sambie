//
//  SambaMount.swift
//  Sambie
//
//  Utility to mount SMB shares using SMBClient.
//
//  Created by Kaeo McKeague-Clark on 10/21/25.
//

import KeychainAccess
import SwiftData
import Foundation
import NetFS

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
        // Perform the actual mount via `mount_smbfs`:
        try await SambaMount.mountShare(mountData: mountData)

        await logger("Mounted \(mountData.host)/\(mountData.share)", level: .info)
    }
    
    /// Mount the share via NetFS. This function will:
    /// - Look up the password in Keychain (server = mountData.host, protocol = smb),
    /// - Pass the password to NetFS when found to avoid UI prompts,
    /// - Otherwise pass nil so NetFS/system may prompt or consult Keychain itself.
    static func mountShare(mountData: MountDataObject) async throws {
        let urlString = try await self.buildSMBURL(from: mountData)
        let password = await self.retrievePassword(for: mountData)
        let mountPath = try await self.performMount(
            urlString: urlString,
            username: mountData.user,
            password: password
        )
        
        await logger("NetFS mounted at: \(mountPath)", level: .info)
    }
    
    // MARK: - Private Helpers
    /// Build the SMB URL string from the mount data.
    @MainActor
    private static func buildSMBURL(from mountData: MountDataObject) throws -> String {
        let url = SambaURL.create(from: mountData)
        guard !url.absoluteString.isEmpty else {
            throw ClientError.mountFailed(reason: "Failed to construct SMB URL.")
        }
        return url.absoluteString
    }

    /// Retrieve the password for the specified mount data from the Keychain.
    /// - Parameter mountData: The mount data object containing host and user information.
    private static func retrievePassword(for mountData: MountDataObject) async -> String? {
        do {
            let keychain = Keychain(server: mountData.host, protocolType: .smb)
            return try keychain.get(mountData.user)
        } catch {
            await logger("Keychain access failed for \(mountData.user)@\(mountData.host)", level: .debug)
            return nil
        }
    }
    
    /// Use NetFS to mount.
    /// - Parameters:
    ///   - urlString: The SMB URL string.
    ///   - username: The username for authentication.
    ///   - password: The password for authentication (optional).
    private static func performMount(
        urlString: String,
        username: String,
        password: String?
    ) async throws -> String {
        // Perform the mount asynchronously:
        let (status, mountPaths) = await withCheckedContinuation { (continuation: CheckedContinuation<(Int32, [String]?), Never>) in
            Task.detached {
                // Attempt to create a Core Foundation URL (CFURL) from the provided SMB URL string:
                // - kCFAllocatorDefault: Uses the default memory allocator.
                // - urlString as CFString: The SMB URL string, cast to CFString.
                // - nil: No base URL is provided (the string must be absolute).
                // If the URL is invalid (e.g., malformed), resume the continuation with an error code (-1) and return.
                guard let serverURL = CFURLCreateWithString(kCFAllocatorDefault, urlString as CFString, nil) else {
                    continuation.resume(returning: (-1, nil))
                    return
                }
                
                // Mount:
                var localMountPoints: Unmanaged<CFArray>?
                let osStatus = NetFSMountURLSync(
                    serverURL,
                    nil,  // Let NetFS choose /Volumes/<share>
                    username as CFString?,
                    password as CFString?,
                    nil,
                    nil,
                    &localMountPoints
                )
                
                let extractedPaths = Self.extractMountPaths(from: localMountPoints)
                continuation.resume(returning: (osStatus, extractedPaths))
            }
        }
        
        // Throw if mount failed:
        guard status == 0, let path = mountPaths?.first else {
            throw ClientError.mountFailed(reason: "NetFS mount failed with status: \(status)")
        }
        
        return path
    }
    
    /// Extract mount paths from the unmanaged CFArray returned by NetFS.
    /// - Parameter unmanaged: The unmanaged CFArray containing mount paths.
    /// - Returns: An array of mount path strings, or nil if extraction fails.
    private static func extractMountPaths(from unmanaged: Unmanaged<CFArray>?) -> [String]? {
        guard let unmanaged = unmanaged else { return nil }
        
        let cfArray = unmanaged.takeRetainedValue()
        let nsArray = cfArray as NSArray
        
        // Convert NSArray elements to String paths, handling possible types.
        let paths: [String] = nsArray.compactMap { element in
            // If the element is already a String, return it directly.
            if let stringPath = element as? String { return stringPath }
            // If the element is a URL, extract its path.
            if let url = element as? URL { return url.path }
            // If the element is an NSURL, cast to URL and extract its path.
            if let nsurl = element as? NSURL { return (nsurl as URL).path }
            // If the element is none of the above, ignore it.
            return nil
        }
        
        return paths.isEmpty ? nil : paths
    }
}
