//
//  Mount+validation.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/26/25.
//

import SwiftData
import SwiftUI
import KeychainAccess

/// Helpers to check for the existence of Mount objects.
extension Mount {
    
    /// Checks if the model is newly inserted into the context and not yet saved.
    func isNew(in context: ModelContext) -> Bool {
        self.isTemporary || context.insertedModelsArray.contains(where: {
            $0.persistentModelID == self.persistentModelID
        })
    }
    
    /// Creates a `MountDataObject` from the current `Mount` instance.
    /// Calls the keychain to retrieve the stored password.
    /// Also calls MountPointServices and fetches if the mount point exists.
    /// - Throws: `ConfigurationError.keychainUnaccessible` if the keychain cannot be accessed.
    /// - Returns: A `MountDataObject` representing the current mount.
    func toDataObject() async -> MountDataObject {
        let mountPoint = await MountPointService.getMountPoint(
            forHost: self.host,
            share: self.share
        )
        
        return MountDataObject(
            persistentID: self.persistentModelID,
            id: self.id,
            order: self.order,
            name: self.name,
            user: self.user,
            host: self.host,
            port: self.port,
            share: self.share,
            mountPoint: mountPoint
        )
    }
    
    /// Checks if the current mount instance exists in the database with the given context.
    @MainActor func exists(context: ModelContext) -> Bool {
        return Mount.exists(persistentID: self.persistentModelID, context: context)
    }

    /// Checks if a mount with the given persistent identifier exists in the database with the given context and ID.
    @MainActor static func exists(
        persistentID: PersistentIdentifier,
        context: ModelContext
    ) -> Bool {
        let internalID = persistentID
        
        do {
            // Try to fetch a model with this persistent ID from the database:
            let descriptor = FetchDescriptor<Mount>(
                predicate: #Predicate { $0.persistentModelID == internalID }
            )
            
            // If we return at least one, the mount exists:
            return try context.fetchCount(descriptor) > 0
        } catch {
            logger("Error checking if mount exists: \(error)", level: .error)
            // If we can't determine, assume it exists to be safe:
            return true
        }
    }
    
    /// Verifies that the mount at the given URL matches this mount's configuration.
    /// - Parameter url: The URL of the mounted volume to verify.
    func verifyIdentity(at url: URL) async -> Bool {
        do {
            // Fetch volume resource values:
            let resourceValues = try url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeURLForRemountingKey,
                .volumeIsLocalKey
            ])
            
            // Must be remote:
            guard let isLocal = resourceValues.volumeIsLocal, !isLocal else {
                await logger("Mount at \(url.path) is local, not remote", level: .debug)
                return false
            }
            
            // Check share name:
            guard resourceValues.volumeName == self.share else {
                await logger("Share name mismatch: expected \(self.share), got \(resourceValues.volumeName ?? "nil")", level: .debug)
                return false
            }
            
            // Check host from remount URL:
            guard let remountURL = resourceValues.volumeURLForRemounting,
                  remountURL.scheme?.lowercased() == "smb",
                  remountURL.host == self.host else {
                await logger("Host mismatch or invalid remount URL", level: .debug)
                return false
            }
            
            return true
            
        } catch {
            await logger("Failed to verify mount identity: \(error)", level: .debug)
            return false
        }
    }
}
