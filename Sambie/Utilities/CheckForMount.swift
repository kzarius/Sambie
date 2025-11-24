//
//  CheckForMount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/21/25.
//

import Foundation

/// Checks `mount` command to see if a given path is mounted on the system.
/// - Returns: A boolean indicating if the mount is mounted on the system.
func checkForMount(path: String) -> Bool {
    let fileManager = FileManager.default
    
    guard let url = URL(string: path) ?? URL(filePath: path) as URL? else {
        return false
    }
    
    // Check if the path exists:
    guard fileManager.fileExists(atPath: url.path) else {
        return false
    }
    
    // Fetch volume information:
    do {
        let resourceValues = try url.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeIsLocalKey,
            .volumeIsRemovableKey
        ])
        
        // If we can get volume properties, it's mounted.
        // Check if it's a remote volume (SMB, NFS, etc.):
        if let isLocal = resourceValues.volumeIsLocal {
            logger("Volume at \(path) is \(isLocal ? "local" : "remote")", level: .debug)
            return true
        }
        
        // If volumeName exists, it's mounted:
        if resourceValues.volumeName != nil {
            return true
        }
        
    } catch {
        logger("Failed to get volume info for \(path): \(error)", level: .debug)
        return false
    }
    
    return false
}
