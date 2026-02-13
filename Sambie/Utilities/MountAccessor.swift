//
//  MountAccessor.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/13/25.
//

import KeychainAccess
import SwiftData
import Foundation


/// Provides access to Mount objects for backend, non-Main Actor code, that we pass down via environment.
/// View-level, Main actor Swiftdata access should use @Query or @ModelContext directly.
@ModelActor
actor MountAccessor {
    // @ModelActor provides modelContext, which we must initialize via MountAccessor(ModelContainer)
    
    // MARK: - Public Methods
    /// Retrieves all Mount objects.
    func getAllMountIDs() -> [PersistentIdentifier] {
        let fetchDescriptor = FetchDescriptor<Mount>()
        do {
            let mounts = try self.modelContext.fetch(fetchDescriptor)
            return mounts.map { $0.persistentModelID }
        } catch {
            Task { await logger("Failed to fetch mounts: \(error)", level: .error) }
            return []
        }
    }
 
    /// Checks if a mount exists by its ID.
    /// - Parameter mountID: The PersistentIdentifier of the mount to check.
    /// - Returns: True if the mount exists, false otherwise.
    func exists(id mountID: PersistentIdentifier) async -> Bool {
        return ((self.getMount(id: mountID)) != nil)
    }
    
    // MARK: - Data Accessors
    /// Returns an array of tuples with the most important mount data.
    func getData(id mountID: PersistentIdentifier) async -> MountDataObject? {
        guard let mount = self.getMount(id: mountID) else {
            Task { await logger("Attempted to get data for a mount that could not be found.", level: .debug) }
            return nil
        }
        var mountData = await mount.toDataObject()
        // Check if the mount is new:
        mountData.isNew = mount.isNew(in: self.modelContext)
        return mountData
    }

    /// Deletes a Mount by its PersistentIdentifier.
    func deleteMount(id mountID: PersistentIdentifier) async throws {
        guard let mount = self.getMount(id: mountID) else {
            Task { await logger("Attempted to delete a mount that could not be found.", level: .debug) }
            throw ClientError.notFound
        }
            
        self.modelContext.delete(mount)

        // Save context after deleting:
        try self.save()
    }
    
    /// Saves any pending changes in the model context.
    func save() throws { try self.modelContext.save() }

    /// Rolls back any pending changes in the model context.
    func rollback() { self.modelContext.rollback() }
    
    /// Retrieves a Mount object by its PersistentIdentifier and model container.
    func getMount(id mountID: PersistentIdentifier) -> Mount? {
        // Fetch the mount. If it doesn't exist, return nil:
        guard let mount = self.modelContext.model(for: mountID) as? Mount else {
            return nil
        }
        
        return mount
    }
    
    // MARK: - Reconnect Accessors
    /// Marks a mount as unexpectedly disconnected, which will trigger the reconnect logic in the UI.
    func markUnexpectedDisconnect(_ mountID: PersistentIdentifier) throws {
        guard let mount = self.getMount(id: mountID) else {
            Task { await logger("Attempted to mark a mount as unexpectedly disconnected, but it could not be found.", level: .debug) }
            throw ClientError.notFound
        }
        mount.wasUnexpectedlyDisconnected = true
        try self.save()
    }

    /// Clears the unexpected disconnect flag for a mount, which will clear the reconnect UI.
    func clearUnexpectedDisconnect(_ mountID: PersistentIdentifier) throws {
        guard let mount = self.getMount(id: mountID) else {
            Task { await logger("Attempted to clear unexpected disconnect for a mount, but it could not be found.", level: .debug) }
            throw ClientError.notFound
        }
        mount.wasUnexpectedlyDisconnected = false
        try self.save()
    }
}
