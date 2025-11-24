//
//  MountShare+Search.swift
//  Sambie
//
//  Mount point search and verification.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Foundation

extension MountShare {
    
    /// Searches the mount base path for the mounted share.
    func searchForMountPoint() throws -> URL? {
        logger("Searching for mount point in \(mountBasePath)...", level: .debug)
        
        let volumesURL = URL(fileURLWithPath: mountBasePath)

        let contents = try FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: [
                .volumeURLKey,
                .volumeNameKey,
                .volumeURLForRemountingKey,
                .volumeIsLocalKey,
                .volumeIsRemovableKey,
                .volumeTypeNameKey
            ],
            options: [.skipsHiddenFiles]
        )
        
        let matchingVolumes = contents.filter { volumeURL in
            self.isMatchingVolume(volumeURL)
        }
        
        return matchingVolumes.first
    }
    
    /// Verifies if a volume URL matches this share.
    private func isMatchingVolume(_ volumeURL: URL) -> Bool {
        do {
            let resourceValues = try volumeURL.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeURLForRemountingKey,
                .volumeIsLocalKey,
                .volumeIsRemovableKey,
                .volumeTypeNameKey
            ])
            
            // Must be remote
            guard let isLocal = resourceValues.volumeIsLocal, !isLocal else {
                return false
            }
            
            // Should not be removable
            if let isRemovable = resourceValues.volumeIsRemovable, isRemovable {
                return false
            }
            
            // Check volume type is SMB/CIFS
            if let volumeType = resourceValues.volumeTypeName {
                guard volumeType.lowercased().contains("smb") ||
                      volumeType.lowercased().contains("cifs") else {
                    return false
                }
            }
            
            // Exact share name match
            guard let volumeName = resourceValues.volumeName,
                  volumeName == self.share else {
                return false
            }
            
            // Verify remount URL matches
            guard let remountURL = resourceValues.volumeURLForRemounting,
                  remountURL.scheme?.lowercased() == "smb",
                  remountURL.host == self.host else {
                return false
            }
            
            // Verify share path matches
            let sharePath = remountURL.path.trimmingCharacters(
                in: CharacterSet(charactersIn: "/")
            )
            guard sharePath == self.share else {
                return false
            }
            
            return true
        } catch {
            logger("Failed to get resource values: \(error)", level: .debug)
            return false
        }
    }
}
