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
        await self.initializeStates()
    }
    
    deinit { monitoringTask?.cancel() }
    
    
    // MARK: - Public Methods
    func startMonitoring() {
        guard self.monitoringTask == nil else { return }
        
        self.monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.checkInterval))
                guard !Task.isCancelled else { break }
                await self.checkAllMountStates()
            }
        }
        
        logger("Mount monitoring started with \(self.checkInterval)s interval", level: .debug)
    }
    
    
    // MARK: - Private Methods
    /// Updates the state of all mounts in the app.
    private func initializeStates() async {
        // Fetch all mounts
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        
        await logger("Checking mount status for \(mounts.count) mounts...", level: .debug)
        
        // Check each mount's status
        for mount in mounts {
//                let isMounted = await MountClient(with: mount.makeSnapshot()).isMounted()
//                mount.state.status = isMounted ? .connected : .disconnected
        }
        
        await logger("Updated status for \(mounts.count) mounts", level: .debug)
    }
    
    private func checkAllMountStates() async {
        // Retrieve all mounts:
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        
        // Check each mount's status for changes:
        await withTaskGroup(of: (PersistentIdentifier, MountStatus)?.self) { group in
            for mount in mounts {
                group.addTask {
                    // Compare actual mount status with recorded status:
                    let newStatus = await self.checkMountStatus(mount)
                    guard let newStatus = newStatus else { return nil }
                    
                    return (mount.persistentModelID, newStatus)
                }
            }
            
            // Collect results and update:
            for await result in group {
                if let (mountID, newStatus) = result {
                    await self.updateMountStatus(
                        mountID: mountID,
                        newStatus: newStatus
                    )
                }
            }
        }
    }
    
    /// Updates the mount status in the database.
    private func updateMountStatus(mountID: PersistentIdentifier, newStatus: MountStatus) async throws {
        let mounts = await RetrieveMount.getAllMounts(in: self.modelContainer)
        if let mount = mounts.first {
            mount.status = newStatus
            await logger("[\(mount.name)] Status corrected to \(newStatus)", level: .debug)
        }
    }
    
    /// Checks the actual mount status against the recorded status.
    /// - Returns: The new status if it has changed, otherwise nil.
    private func hasStatusChanged(mountID: PersistentIdentifier) async -> MountStatus? {
        let recordedStatus = await RetrieveMount.getMount(id: mountID, in: self.modelContainer)?.status
        
        // Check the mount's recorded database status:
        let actualStatus = await MountClient(forID: mountID).isMounted() ? MountStatus.connected : MountStatus.disconnected
        
        // Return new status only if it differs from recorded status
        return actualStatus != recordedStatus ? actualStatus : nil
    }
}
