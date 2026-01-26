//
//  MountedVolume.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 19/12/2025.
//

import Foundation

/// Represents a mounted filesystem volume.
struct MountedVolume {
    /// The path where the volume is mounted (e.g., `/Volumes/ShareName`).
    let mountPath: String
    /// The source of the mount (e.g., `smb://user@host/share`).
    let sourceURL: URL?
}
