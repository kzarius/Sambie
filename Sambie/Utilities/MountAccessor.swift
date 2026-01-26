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
        return ((try? self.getMount(id: mountID)) != nil)
    }
    
    // MARK: - Data Accessors
    /// Returns an array of tuples with the most important mount data.
    func getData(id mountID: PersistentIdentifier) async throws -> MountDataObject {
        let mount = try self.getMount(id: mountID)
        return try await mount.toDataObject()
    }

    /// Deletes a Mount by its PersistentIdentifier.
    func deleteMount(id mountID: PersistentIdentifier) async throws {
        let mount = try self.getMount(id: mountID)
        self.modelContext.delete(mount)

        // Save context after deleting:
        try self.save()
    }
    
    /// Saves any pending changes in the model context.
    func save() throws { try self.modelContext.save() }

    /// Rolls back any pending changes in the model context.
    func rollback() { self.modelContext.rollback() }
    
    /// Retrieves a Mount object by its PersistentIdentifier and model container.
    func getMount(id mountID: PersistentIdentifier) throws -> Mount {
        // Fetch the mount. If it doesn't exist, return nil:
        guard let mount = self.modelContext.model(for: mountID) as? Mount else {
            Task { await logger("Mount invalidated or not found.", level: .debug) }
            throw ClientError.invalidMount
        }
        
        return mount
    }
}
