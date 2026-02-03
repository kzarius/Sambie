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
    private let accessor: MountAccessor
    private let stateManager: MountStateManager
    
    
    // MARK: - Initializer
    
    /// Initialize the ConnectMount object.
    init(
        mountID: PersistentIdentifier,
        accessor: MountAccessor,
        stateManager: MountStateManager
    ) async {
        // Assign properties:
        self.mountID = mountID
        self.accessor = accessor
        self.stateManager = stateManager

        // Ensure the mount exists:
        if await accessor.exists(id: mountID) == false {
            fatalError("Mount with ID \(mountID) does not exist in accessor. Something isn't right.")
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
        
        // Mount the share:
        _ = try await SambaMount(
            mountID: mountID,
            accessor: accessor
        )
        await logger ("State of mount: \(self.isMounted() ? "mounted" : "not mounted")", level: .debug)
    }
    
    /// Attempt to unmount the directory.
    func doUnmount() async throws {
        // Ensure the mount is actually mounted and discover its path.
        guard let mountPoint = await self.getMountPoint() else {
            await logger("Attempted to unmount, but mount is not currently mounted.", level: .debug)
            return
        }
        
        // Gentle unmount:
        do {
            if try await systemUnmount(path: mountPoint.path) { return }
        } catch ClientError.unmountFailed {
            await logger("Gentle unmount failed, trying force unmount", level: .debug)
        } catch {
            await logger("Gentle unmount error: \(error)", level: .error)
            throw error
        }
        
        // Forcefully unmount:
        try await self.forceUnmount(path: mountPoint.path)
    }
    
    /// Checks to see if the mount is already present.
    /// - Returns: A boolean indicating if the mount is present.
    func isMounted() async -> Bool {
        return await self.getMountPoint() != nil
    }
    
    /// Dismiss the error for the mount, setting it to nil and update the status based on whether the mount is still mounted.
    func dismissError() async {
        await self.updateState(
            status: await self.isMounted() ? .connected : .disconnected
        )
    }
    
    
    // MARK: - Private Methods
    /// Retrieves the current mount point for the share.
    /// - Returns: A `MountedVolume` if found, otherwise `nil`.
    private func getMountPoint() async -> MountedVolume? {
        do {
            let mountData = try await self.accessor.getData(id: self.mountID)
            return await MountPointService.getMountPoint(forHost: mountData.host, share: mountData.share)
        } catch {
            await logger("Failed to get mount data for ID \(self.mountID) to check mount point: \(error)", level: .error)
            return nil
        }
    }
    
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
    
    /// Safely access the mount and update its state.
    private func updateState(status: ConnectionStatus, errors: [Error] = []) async {
        // Ensure the mount still exists before updating state:
        guard await self.accessor.exists(id: self.mountID) else {
            await logger("Mount with ID \(self.mountID) no longer exists, cannot update state.", level: .error)
            return
        }
        
        // Update transient state via manager:
        await self.stateManager.setStatus(status, for: self.mountID)
        if errors.isEmpty {
            await self.stateManager.clearErrors(for: self.mountID)
        } else {
            await self.stateManager.setErrors(
                errors.map { $0.localizedDescription },
                for: self.mountID
            )
        }
    }
}
