//
//  MountClient.swift
//  Sambie
//
//  Handles mounting and unmounting Samba shares. Manages the state of the mount during the process and checks if the mount is already present and mounted.
//
//  Created by Kaeo McKeague-Clark on 3/24/25.
//

import SwiftData
import SwiftUI

/// Handles mounting and unmounting Samba shares. Manages the state of the mount during the process and checks if the mount is already present and mounted.
actor MountClient: Sendable {
    
    // MARK: - Properties
    // The mount's current info that we're connecting to.
    private let mountID: PersistentIdentifier
    private let modelContainer: ModelContainer
    
    
    // MARK: - Initializer
    
    /// Initialize the ConnectMount object.
    init(
        mountID: PersistentIdentifier,
        modelContainer: ModelContainer
    ) async {
        self.mountID = mountID
        self.modelContainer = modelContainer
        guard ((await RetrieveMount.getMount(id: mountID, in: modelContainer)) != nil) else {
            fatalError("Mount with ID \(mountID) not found in model container.")
        }
    }
    
    
    // MARK: - Public Methods
    /// Attempt to mount a samba drive to a directory.
    /// - Note: This function updates the mount's state as it progresses.
    func mount() async {
        await self.updateState(status: .connecting)
        do {
            try await self.doMount()
            await self.updateState(status: .connected)
        } catch {
            let status = await self.isMounted() ? ConnectionStatus.connected : ConnectionStatus.disconnected
            await self.updateState(status: status, errors: [error])
        }
    }
    
    func unmount() async {
        await self.updateState(status: .disconnecting)
        do {
            try await self.doUnmount()
            await self.updateState(status: .disconnected)
        } catch {
            let status = await self.isMounted() ? ConnectionStatus.connected : ConnectionStatus.disconnected
            await self.updateState(status: status, errors: [error])
        }
    }
    
    /// Attempt to mount the directory.
    /// - Note: This function will check if the mount is already present, and if it is, it will return early.
    /// - Note: If the mount is stubborn, it will attempt to force unmount it.
    /// - Returns: A MountState indicating the status of the mount operation.
    func doMount() async throws {
        // If the mount is already connected, return early:
        if await self.isMounted() { return }
        
        guard let mount = await RetrieveMount.getMount(id: mountID, in: modelContainer) else {
            throw ClientError.invalidMount
        }
        
        // Check if everything is prepped to attempt a mount:
        try await MountReadiness.checkMount(
            host: mount.host,
            customMountPoint: mount.customMountPoint
        )
        
        // Mount the share:
        let mountedAt = try await MountShare(
            host: mount.host,
            share: mount.share,
            username: mount.user,
            password: nil, // Always nil - let macOS handle it.
            customMountPoint: mount.customMountPoint,
        ).mount()
        
        await mount.setActualMountPoint(mountedAt)
    }
    
    /// Attempt to unmount the directory.
    func doUnmount() async throws {
        // Retrieve the mount object. If it doesn't exist, throw an error:
        guard let mount = await RetrieveMount.getMount(id: self.mountID, in: self.modelContainer) else {
            throw ClientError.invalidMount
        }
        
        // 1.) If the mount is already disconnected, return early:
        if await !self.isMounted() {
            // Clear actual mount point since it's not mounted:
            await mount.clearActualMountPoint()
            return
        }
        
        // 2.) Determine the path to unmount:
        let unmountPath: String
        if let actualMount = mount.actualMountPoint {
            unmountPath = actualMount.path
        } else if let customMount = mount.customMountPoint {
            unmountPath = customMount.path
        } else {
            // No path available - cannot unmount
            throw ClientError.mountpointDoesNotExist
        }
        
        // 3.) Gentle unmount:
        do {
            if try await systemUnmount(path: unmountPath) {
                await mount.clearActualMountPoint()
                return
            }
        } catch ClientError.unmountFailed {
            await logger("Gentle unmount failed, trying force unmount", level: .debug)
        } catch {
            await logger("Gentle unmount error: \(error)", level: .error)
            throw error
        }
        
        // 4.) Forceful unmount:
        // If the mount is stubborn, force unmount it:
        try await self.forceUnmount(path: unmountPath)
        await mount.clearActualMountPoint()
    }
    
    /// Checks to see if the mount is already present.
    /// - Returns: A boolean indicating if the mount is present.
    /// - Note: This function uses a combination of `df` and `grep` to check if the source is mounted.
    func isMounted() async -> Bool {
        await logger("Checking if mount is mounted...", level: .debug)
        
        // Retrieve the mount object. If it doesn't exist, return false:
        guard let mount = await RetrieveMount.getMount(id: mountID, in: modelContainer) else {
            await logger("The mount does not exist in the database.", level: .error)
            return false
        }
        
        // Check in order of priority:
        if await self.checkActualMountPoint(mount: mount) { return true }
        if await self.checkCustomMountPoint(mount: mount) { return true }
        if await self.checkDefaultDirectory(mount: mount) { return true }

        await logger("Mount not found via mountpoints or in the default directory.", level: .debug)
        return false
    }
    
    /// Dismiss the error for the mount, setting it to nil and update the status based on whether the mount is still mounted.
    func dismissError() async {
        await self.updateState(
            status: await self.isMounted() ? .connected : .disconnected
        )
    }
    
    
    // MARK: - Private Methods
    /// If the mount is stubborn, force unmount it.
    /// - Parameter path: The path to unmount.
    private func forceUnmount(path: String) async throws {
        let unmountSuccess = try await systemUnmount(
            path: path,
            forcefully: true
        )
        
        guard unmountSuccess else { throw ClientError.unmountFailed }
        
        // Brief delay for filesystem:
        try await Task.sleep(for: .milliseconds(500))
        
        // Verify unmount:
        if await self.isMounted() {
            throw ClientError.unmountTimedOut
        }
    }
    
    /// Check the actual mount point for the mount.
    private func checkActualMountPoint(mount: Mount) async -> Bool {
        guard let actualMount = mount.actualMountPoint else { return false }

        await logger("Checking actual mount point at path: \(actualMount.path)", level: .debug)

        let mountExists = await checkForMount(path: actualMount.path)
        let identityVerified = await mount.verifyIdentity(at: actualMount)

        if mountExists && identityVerified {
            await logger("Mount verified at actual mount point", level: .debug)
            return true
        }

        await logger("Mount not found or identity mismatch; clearing it", level: .debug)
        await mount.clearActualMountPoint()
        return false
    }

    /// Check the custom mount point for the mount.
    private func checkCustomMountPoint(mount: Mount) async -> Bool {
        guard let customMount = mount.customMountPoint else { return false }

        await logger("Checking custom mount point at path: \(customMount.path)", level: .debug)

        let mountExists = await checkForMount(path: customMount.path)
        let identityVerified = await mount.verifyIdentity(at: customMount)

        if mountExists && identityVerified {
            await logger("Mount verified at custom mount point", level: .debug)
            await mount.setActualMountPoint(customMount)
            return true
        }

        return false
    }

    /// Search the default mount directory for a match with our mount.
    private func checkDefaultDirectory(mount: Mount) async -> Bool {
        await logger("Searching default mount directory...", level: .debug)

        if let foundMount = await mount.searchDefaultDirectory() {
            await logger("Found mount at \(foundMount.path)", level: .debug)
            await mount.setActualMountPoint(foundMount)
            return true
        }

        return false
    }
    
    /// Safely access the mount and update its state
    private func updateState(status: ConnectionStatus, errors: [Error] = []) async {
        await MainActor.run {
            guard let mount = RetrieveMount.getMount(id: self.mountID, in: self.modelContainer) else {
                logger("Mount with ID \(self.mountID) no longer exists", level: .error)
                return
            }
            mount.updateState(status: status, errors: errors)
        }
    }
}
