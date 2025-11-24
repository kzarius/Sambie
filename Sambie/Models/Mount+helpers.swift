//
//  Mount+helpers.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/14/25.
//

import SwiftData
import SwiftUI

extension Mount {
    /// exists() caller for the current mount instance.
    func exists(context: ModelContext) -> Bool {
        return Mount.exists(persistentID: self.persistentModelID, context: context)
    }
    
    /// Checks if a mount with the given persistent identifier exists in the database.
    static func exists(
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
    
    /// Conventience method to update the status and error of the mount.
    /// - Parameters:
    ///  - status: The new connection status.
    ///  - errors: An optional array of errors to append to the mount's error list. If not provided, clears existing errors.
    func updateState(status: ConnectionStatus, errors: [Error] = []) {
        self.status = status
        
        // Clear errors if none provided:
        if errors.isEmpty {
            self.errors = []
        // Otherwise append them to the array:
        } else {
            for error in errors {
                self.addError(error)
            }
        }
    }
    
    /// Verifies that the mount at the given URL matches this mount's configuration.
    /// - Parameter url: The URL of the mounted volume to verify.
    func verifyIdentity(at url: URL) async -> Bool {
        do {
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
    
    /// Searches the default mount directory for this mount
    func searchDefaultDirectory() async -> URL? {
        await logger("Searching default mount directory for \(self.name)...", level: .debug)
        
        let volumesURL = await URL(fileURLWithPath: Config.Paths.sambaMountBase)
        
        do {
            // List contents of the default mount directory:
            let contents = try FileManager.default.contentsOfDirectory(
                at: volumesURL,
                includingPropertiesForKeys: [
                    .volumeNameKey,
                    .volumeURLForRemountingKey,
                    .volumeIsLocalKey,
                    .volumeTypeNameKey
                ],
                options: [.skipsHiddenFiles]
            )
            
            // Check each volume for a match:
            for volumeURL in contents {
                if await verifyIdentity(at: volumeURL) {  // Use existing verifyIdentity
                    await logger("Found mount at \(volumeURL.path)", level: .debug)
                    return volumeURL
                }
            }
            
            await logger("No matching mount found in default directory", level: .debug)
            return nil
            
        } catch {
            await logger("Failed to search default directory: \(error)", level: .error)
            return nil
        }
    }
    
    /// Generates a default mount point URL based on the mount's name.
    func generateMountPoint() -> URL {
        return URL(fileURLWithPath: "\(Config.Paths.sambaMountBase)\(self.name)")
    }
    
    /// Adds an error message to the mount's error list.
    func addError(_ error: Error) {
        self.errors.append(error.localizedDescription)
    }
    
    /// Updates the actual mount point after a successful mount operation.
    /// Must be called on MainActor for proper SwiftUI observation.
    @MainActor
    func setActualMountPoint(_ url: URL) {
        self.actualMountPoint = url
    }
    
    /// Clears the actual mount point after unmounting.
    /// Must be called on MainActor for proper SwiftUI observation.
    @MainActor
    func clearActualMountPoint() {
        self.actualMountPoint = nil
    }
}
