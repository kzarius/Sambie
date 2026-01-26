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

        guard let mountedURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: []
        ) else {
            return []
        }

        return mountedURLs.compactMap { url in
            do {
                let resourceValues = try url.resourceValues(forKeys: Set(keys))

                guard let sourceURL = resourceValues.volumeURLForRemounting,
                      sourceURL.scheme?.lowercased() == "smb" else {
                    return nil
                }

                return MountedVolume(mountPath: url.path, sourceURL: sourceURL)
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
}
