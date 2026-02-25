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
        guard let mountData = await self.accessor.getData(id: self.mountID) else {
            await logger("Attempted to unmount, but mount data could not be retrieved.", level: .error)
            throw ClientError.notFound
        }
        
        // If the mount is already unmounted, return early:
        do {
            try await SambaMount.checkForMountInSystem(
                user: mountData.user,
                host: mountData.host,
                share: mountData.share
            )
        } catch {
            await logger("Attempted to unmount, but mount is not currently mounted.", level: .debug)
            return
        }
        
        // Get the mount point for the share:
        let mountPoint = try await SambaMount.getMountPath(
            user: mountData.user,
            host: mountData.host,
            share: mountData.share
        )
        
        // Gentle unmount:
        do {
            if try await systemUnmount(path: mountPoint) { return }
        } catch ClientError.unmountFailed {
            await logger("Gentle unmount failed, trying force unmount", level: .debug)
        } catch {
            await logger("Gentle unmount error: \(error)", level: .error)
            throw error
        }
        
        // Forcefully unmount:
        try await self.forceUnmount(path: mountPoint)
    }
    
    /// Checks to see if the mount is already present.
    /// - Returns: A boolean indicating if the mount is present.
    func isMounted() async -> Bool {
        do {
            guard let mountData = await self.accessor.getData(id: self.mountID) else {
                await logger("Attempted to check if mount is mounted, but mount data could not be retrieved.", level: .error)
                throw ClientError.notFound
            }
            
            await logger("Checking if mount `\(SambaURL.create(from: mountData))` is mounted...", level: .debug)
            
            try await SambaMount.checkForMountInSystem(
                user: mountData.user,
                host: mountData.host,
                share: mountData.share
            )
            await logger(" - ✅ Mount is mounted.", level: .debug)
        } catch {
            await logger(" - ❌ Mount is not mounted.", level: .debug)
            return false
        }
        
        return true
    }
    
    /// Dismiss the error for the mount, setting it to nil and update the status based on whether the mount is still mounted.
    func dismissError() async {
        await self.updateState(
            status: await self.isMounted() ? .connected : .disconnected
        )
    }
    
    /// Skips gentle unmount and goes straight to force unmount.
    /// Used when the server is suspected unreachable (zombie mount).
    func forceUnmountZombie() async {
        await self.updateState(status: .disconnecting)
        do {
            await logger("Attempting to force unmount suspected zombie mount with ID \(self.mountID)", level: .warning)
            
            // Retrieve mount data:
            guard let mountData = await self.accessor.getData(id: self.mountID) else {
                await logger("🧟 Attempted to force unmount zombie, but mount data could not be retrieved.", level: .error)
                await self.updateState(status: .connected)
                return
            }

            // Get the mount point for the share:
            let mountPoint = try await SambaMount.getMountPath(
                user: mountData.user,
                host: mountData.host,
                share: mountData.share
            )

            // Force unmount:
            try await self.forceUnmount(path: mountPoint)
            await self.updateState(status: .disconnected)
            await logger("🧟 Successfully force unmounted suspected zombie mount with ID \(self.mountID)", level: .warning)
        } catch {
            let status = await self.isMounted() ? ConnectionStatus.connected : ConnectionStatus.disconnected
            await self.updateState(status: status, errors: [error])
        }
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
