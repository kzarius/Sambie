//
//  MountMonitor.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI

actor MountMonitor {
    
    // MARK: - Properties
    private let modelContainer: ModelContainer
    private var monitoringTask: Task<Void, Never>?
    private let checkInterval: TimeInterval
    
    
    // MARK: - Initializer
    init(modelContainer: ModelContainer) async {
        self.modelContainer = modelContainer
        self.checkInterval = await Config.Connection.checkMountInterval
        
        // Fetch all mounts
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        
        // Check each mount's status
        for mount in mounts {
            mount.status = await MountClient(
                mountID: mount.persistentModelID,
                modelContainer: self.modelContainer
            ).isMounted() ? .connected : .disconnected
        }
    }
    
    deinit { monitoringTask?.cancel() }
    
    
    // MARK: - Public Methods
    func startMonitoring() async {
        guard self.monitoringTask == nil else { return }
        
        self.monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.checkInterval))
                guard !Task.isCancelled else { break }
                await self.updateAllStatuses()
            }
        }
    }
    
    
    // MARK: - Private Methods
    /// Updates the state of all mounts in the app.
    private func initializeStates() async {
        // Fetch all mounts
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        
        await logger("Checking mount status for \(mounts.count) mounts...", level: .debug)
        
        // Check each mount's status
        await self.updateAllStatuses()
        
        await logger("Updated status for \(mounts.count) mounts", level: .debug)
    }
    
    /// Checks and updates the status of all mounts.
    private func updateAllStatuses() async {
        // Retrieve all mounts:
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        
        // Check each mount's status for changes:
        for mount in mounts {
            // Compare actual mount status with recorded status:
            let checkedStatus = await self.hasStatusChanged(mountID: mount.persistentModelID)
            guard let statusChanged = checkedStatus else { return }
            
            do {
                try await self.updateStatus(mountID: mount.persistentModelID, newStatus: statusChanged)
            } catch {
                await logger("Failed to update status for mount \(mount.name): \(error)", level: .error)
            }
        }
    }
    
    /// Updates the mount status in the database.
    /// - Parameters:
    ///  - mountID: The PersistentIdentifier of the mount.
    ///  - newStatus: The new ConnectionStatus to set.
    ///  - Throws: An error if the update fails.
    private func updateStatus(mountID: PersistentIdentifier, newStatus: ConnectionStatus) async throws {
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        if let mount = mounts.first {
            mount.status = newStatus
            await logger("[\(mount.name)] Status corrected to \(newStatus)", level: .debug)
        }
    }
    
    /// Checks the actual mount status against the recorded status.
    /// - Returns: The new status if it has changed, otherwise nil.
    private func hasStatusChanged(mountID: PersistentIdentifier) async -> ConnectionStatus? {
        let recordedStatus = await RetrieveMount.getMount(id: mountID, in: self.modelContainer)?.status
        
        // Check the mount's recorded database status:
        let actualStatus: ConnectionStatus = await MountClient(mountID: mountID, modelContainer: self.modelContainer).isMounted() ? .connected : .disconnected
        
        // Return new status only if it differs from recorded status
        return actualStatus != recordedStatus ? actualStatus : nil
    }
}
