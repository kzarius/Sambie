//
//  MountPointService.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 2/1/2026.
//

import Foundation

/// A service to query the operating system for mounted SMB volumes.
/// This is done to determine if a mount is currently mounted or has ceased.
struct MountPointService {

    /// Retrieves a list of all mounted SMB filesystems on the system.
    /// - Returns: An array of `MountedVolume` structs representing SMB mounts.
    static func getAllMountPoints() -> [MountedVolume] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.volumeURLForRemountingKey]

        // Get all mounted volume URLs:
        guard let mountedURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: []
        ) else {
            return []
        }

        // Cycle through the collected mounts:
        return mountedURLs.compactMap { url -> MountedVolume? in
            do {
                // Fetch resource values for the URL:
                let resourceValues = try url.resourceValues(forKeys: Set(keys))

                // Check if the volume is an SMB mount:
                guard let sourceURL = resourceValues.volumeURLForRemounting,
                      sourceURL.scheme?.lowercased() == "smb" else {
                    return nil
                }

                return MountedVolume(path: url.path, sourceURL: sourceURL)
            } catch {
                return nil
            }
        }
    }

    /// Finds the mount point for a specific host and share name.
    /// - Parameters:
    ///   - host: The host of the share.
    ///   - share: The name of the share.
    /// - Returns: A `MountedVolume` struct if found, otherwise `nil`.
    static func getMountPoint(forHost host: String, share: String) -> MountedVolume? {
        let allMounts = MountPointService.getAllMountPoints()

        return allMounts.first { mountedVolume in
            guard let mountedHost = mountedVolume.sourceURL?.host else { return false }
            let mountedShare = String(mountedVolume.sourceURL?.path.dropFirst() ?? "")

            return mountedHost.caseInsensitiveCompare(host) == .orderedSame &&
                   mountedShare.caseInsensitiveCompare(share) == .orderedSame
        }
    }
    
    /// Creates a mount point directory for a given mount name.
    /// - Parameter mountName: The name of the mount.
    /// - Returns: The full path to the created mount point.
    static func createMountPoint(from mountData: MountDataObject) throws -> MountedVolume {
        // Create URL:
        let mountURL = SambaURL.create(from: mountData)
        
        // Expand ~ to full path
        let basePath = (Config.Paths.sambaMountBase as NSString).expandingTildeInPath
        let fm = FileManager.default

        // Create base mount directory if it doesn't exist:
        try fm.createDirectory(
            atPath: basePath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Assemble the mount point path:
        let mountPoint = (basePath as NSString).appendingPathComponent(mountData.id.uuidString)

        try fm.createDirectory(
            atPath: mountPoint,
            withIntermediateDirectories: true,
            attributes: nil
        )
        logger("Mount point created at \(mountPoint) via \(mountURL)", level: .debug)
        
        return MountedVolume(
            path: mountPoint,
            sourceURL: mountURL
        )
    }
}
