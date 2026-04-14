//
//  MountAccessor.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/13/25.
//

import KeychainAccess
import SwiftData
import SwiftUI


/// Provides access to Mount objects for backend, non-Main Actor code, that we pass down via environment.
/// View-level, Main actor Swiftdata access should use @Query or @ModelContext directly.
@ModelActor
actor MountAccessor {
    // @ModelActor provides modelContext, which we must initialize via MountAccessor(ModelContainer)
    
    // MARK: - Public Methods
    /// Retrieves all Mount IDs grouped by their host's PersistentIdentifier.
    /// - Returns: A dictionary where each key is a host's PersistentIdentifier, and the value is an array of Mount PersistentIdentifiers belonging to that host.
    func getMountIDs() -> [PersistentIdentifier: [PersistentIdentifier]] {
        // Create a fetch descriptor to get all Mounts, sorted by their 'order' property:
        let descriptor = FetchDescriptor<Mount>(sortBy: [SortDescriptor(\.order)])
        do {
            // Fetch all Mount objects from the model context:
            let mounts = try self.modelContext.fetch(descriptor)
            
            // Group mounts by their host's persistentModelID (hostID, mountID):
            let grouped = Dictionary(
                grouping: mounts.compactMap { mount -> (PersistentIdentifier, PersistentIdentifier)? in
                    
                    // Only include mounts that have a host:
                    guard let hostID = mount.host?.persistentModelID else { return nil }
                    return (hostID, mount.persistentModelID)
                },
                // Group by hostID:
                by: { $0.0 }
            )
            
            // Transform the grouped dictionary to map each hostID to an array of mountIDs:
            return grouped.mapValues { $0.map(\.1) }
        } catch {
            Task { await logger("Failed to fetch mounts grouped by host: \(error)", level: .error) }
            return [:]
        }
    }

    /// Retrieves Mount IDs for a specific host, sorted by order.
    /// - Parameter hostID: The PersistentIdentifier of the host to filter by.
    func getMountIDs(forHost hostID: PersistentIdentifier) -> [PersistentIdentifier] {
        self.getMountIDs()[hostID] ?? []
    }
 
    /// Checks if a mount exists by its ID.
    /// Does so by attempting to fetch a count of mounts with the given PersistentIdentifier instead of fetching the full model, to avoid issues with invalidated models.
    /// - Parameter mountID: The PersistentIdentifier of the mount to check.
    /// - Returns: True if the mount exists, false otherwise.
    func exists(id mountID: PersistentIdentifier) async -> Bool {
        let internalID = mountID
        let descriptor = FetchDescriptor<Mount>(
            predicate: #Predicate { $0.persistentModelID == internalID }
        )
        return (try? self.modelContext.fetchCount(descriptor) > 0) ?? false
    }
    
    // MARK: - Data Accessors
    /// Returns a `MountDataObject` (with embedded `HostDataObject`) for the given mount ID.
    func getData(id mountID: PersistentIdentifier) async -> MountDataObject? {
        // Use exists check first to avoid accessing invalidated models:
        guard await self.exists(id: mountID) else { return nil }
        
        // Fetch the mount. If it doesn't exist, return nil:
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
            
        let host = mount.host
        self.modelContext.delete(mount)
        
        // Delete the host group if this was its last mount:
        if let host, host.mounts.isEmpty {
            self.modelContext.delete(host)
        }

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
    
    /// Marks the last time a mount was successfully connected.
    func markLastConnected(_ mountID: PersistentIdentifier) throws {
        guard let mount = self.getMount(id: mountID) else {
            throw ClientError.notFound
        }
        mount.lastConnectedAt = Date()
        try self.save()
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
    
    // MARK: - Host Methods
    /// Retrieves all Host IDs, sorted by their order. Used for listing hosts in the UI, and for grouping mounts by host.
    func getAllHostIDs() -> [PersistentIdentifier] {
        let descriptor = FetchDescriptor<Host>(sortBy: [SortDescriptor(\.order)])
        do {
            return try self.modelContext.fetch(descriptor).map { $0.persistentModelID }
        } catch {
            Task { await logger("Failed to fetch hosts: \(error)", level: .error) }
            return []
        }
    }

    /// Retrieves a Host object by its PersistentIdentifier and model container.
    func getHost(for hostID: PersistentIdentifier) -> Host? {
        guard self.doesHostExist(for: hostID) else { return nil }
        return self.modelContext.model(for: hostID) as? Host
    }
    
    /// Returns a `HostDataObject` for the given host ID, or nil if the Host doesn't exist.
    func getHostData(for hostID: PersistentIdentifier) -> HostDataObject? {
        self.getHost(for: hostID)?.toDataObject()
    }
    
    /// Updates the palette for a Host and saves.
    func setHostPalette(
        for hostID: PersistentIdentifier,
        palette: Config.UI.Colors.Palette
    ) throws {
        guard let host = self.getHost(for: hostID) else { throw ClientError.notFound }
        host.paletteName = palette.rawValue
        try self.save()
    }
    
    /// Updates the order for a Host and saves.
    func setHostOrder(for hostID: PersistentIdentifier, order: Int) throws {
        guard let host = self.getHost(for: hostID) else { throw ClientError.notFound }
        host.order = order
        try self.save()
    }

    /// Checks if a Host exists by its ID.
    func doesHostExist(for hostID: PersistentIdentifier) -> Bool {
        let internalID = hostID
        let descriptor = FetchDescriptor<Host>(
            predicate: #Predicate { $0.persistentModelID == internalID }
        )
        return (try? self.modelContext.fetchCount(descriptor) > 0) ?? false
    }

    /// Finds an existing Host by hostname, or creates one if none exists.
    /// Use this when inserting a new Mount so they get grouped automatically.
    func findOrCreateHost(hostname: String, port: Int) throws -> Host {
        let descriptor = FetchDescriptor<Host>(
            predicate: #Predicate { $0.hostname == hostname }
        )
        
        // First attempt to find an existing Host with the same hostname:
        if let existing = try self.modelContext.fetch(descriptor).first {
            return existing
        }

        // Determine next order value:
        let allDescriptor = FetchDescriptor<Host>(sortBy: [SortDescriptor(\.order, order: .reverse)])
        let maxOrder = (try? self.modelContext.fetch(allDescriptor).first?.order) ?? -1

        let host = Host(hostname: hostname, port: port, order: maxOrder + 1)
        self.modelContext.insert(host)
        return host
    }

    /// Deletes a Host by its PersistentIdentifier. Will throw an error if the Host has any Mounts, to prevent orphaned Mounts.
    func deleteHost(for hostID: PersistentIdentifier) throws {
        guard let host = self.getHost(for: hostID) else {
            throw ClientError.notFound
        }
        guard host.mounts.isEmpty else {
            throw ClientError.deleteDenied
        }
        self.modelContext.delete(host)
        try self.save()
    }
    
    /// Checks if a host's SMB port is accessible.
    func isHostReachable(id hostID: PersistentIdentifier, timeout: TimeInterval = 5.0) async -> Bool {
        guard let host = self.getHost(for: hostID) else { return false }
        return await host.isReachable(timeout: timeout)
    }

    /// Verifies that a host's SMB port is accessible, throwing if not.
    func checkHostPortAccessible(id hostID: PersistentIdentifier, timeout: TimeInterval = 5.0) async throws {
        guard let host = self.getHost(for: hostID) else { throw ClientError.notFound }
        try await self.checkHostPortAccessible(for: host.toDataObject(), timeout: timeout)
    }
    
    func checkHostPortAccessible(for hostObject: HostDataObject, timeout: TimeInterval = 5.0) async throws {
        try await Host.checkPortAccessible(host: hostObject.hostname, port: hostObject.port, timeout: timeout)
    }
}
