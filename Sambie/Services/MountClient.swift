//
//  MountClient.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 3/24/25.
//

import SwiftUI

/// A wrapper for the mount state that can be sent across actors.
struct MountStateWrapper: Sendable {
    let status: MountStatus
    let error: MountError?
    
    init (state: MountState) {
        self.init(
            status: state.status,
            error: state.error
        )
    }
    
    init (status: MountStatus, error: MountError? = nil) {
        self.status = status
        self.error = error
    }
}

/// A client that handles mounting and unmounting directories using SSHFS.
actor MountClient: Sendable {
    
    // MARK: - Properties
    
    // The mount's current info that we're connecting to.
    private var snapshot: MountSnapshot
    
    
    
    // MARK: - Initializer
    
    /// Initialize the ConnectMount object.
    init(with snapshot: MountSnapshot) async { self.snapshot = snapshot }
    
    
    
    // MARK: - Public Methods
    
    /// Attempt to mount the directory.
    /// - Note: This function will check if the mount is already present, and if it is, it will return early.
    /// - Note: If the mount is stubborn, it will attempt to force unmount it.
    /// - Returns: A MountState indicating the status of the mount operation.
    func doMount() async -> MountStateWrapper {
        // If the mount is already connected, return early:
        if await self.isMounted() {
            return self.successfulMount()
        }
        
        do {
            // Check if everything is prepped to attempt a mount:
            try await SSHFS.checkReady(self.snapshot)
            
            // Mount and throw errors if the mount fails:
            try await SSHFS.mount(self.snapshot)
            
            return self.successfulMount()
            
        // If the error is a MountError, then we are probably catching it from SSHFSResults:
        } catch let error as MountError {
            
            switch error {
                    
            // The mount failed because the source is already mounted:
            case .already_mounted:
                // Check if the mount present is the same as the one we're trying to mount:
                if await self.isMounted() {
                    return self.successfulMount()
                }
                
                // If the mount is different, throw error:
                return await self.failedMounting(
                    because: MountError.mount_exists(
                        path: self.snapshot.paths.target
                    )
                )
                
            // Unable to connect because of a network issue:
            case .io_error:
                return await self.failedMounting(because: MountError.io_error)
                
            // The mount failed for an unkown reason, but we have output:
            case .unknown(let code, let output):
                return await self.failedMounting(
                    because: MountError.unknown(
                        code: code,
                        output: output
                    )
                )
                
            // If the mount failed for some other reason, throw an error:
            default:
                return await self.failedMounting(because: error)
            }
        } catch {
            logger("Encountered an error while mounting.", level: .error, snapshot: self.snapshot)
            return await self.failedMounting(because: .unknown())
        }
    }
    
    
    /// Attempt to unmount the directory.
    func doUnmount() async -> MountStateWrapper {
        // 1.) If the mount is already disconnected, return early:
        if await !self.isMounted() {
            return self.successfulUnmount()
        }
        
        // 2.) Gentle unmount:
        do {
            // Try to unmount gently:
            if try await diskutilUnmount(path: self.snapshot.paths.target) {
                return self.successfulUnmount()
            }
        } catch MountError.unmount_failed {
            // If the unmount failed, we need to force unmount it:
            logger("Failed to gently unmount.", level: .debug, snapshot: self.snapshot)
        } catch {
            // If the unmount failed for some other reason, throw the error:
            logger("Failed unmounting gently.", level: .debug, snapshot: self.snapshot)
        }
        
        
        // 3.) Forceful unmount:
        do {
            // If the mount is stubborn, force unmount it:
            var unmount_success = false
            try await self.forceUnmount { success in
                unmount_success = success
            }
            
            if unmount_success {
                return self.successfulUnmount()
            }
        } catch {
            logger("Failed unmounting forcefully.", level: .debug, snapshot: self.snapshot)
            
            // If the error is a MountError, handle it accordingly:
            if let mount_error = error as? MountError {
                return await self.failedMounting(because: mount_error)
            // Otherwise, it's an unknown error:
            } else {
                return await self.failedMounting(because: .unknown())
            }
        }
        
        return await self.failedMounting(because: .unmount_failed)
    }
    
    
    /// Checks to see if the mount is already present.
    /// - Returns: A boolean indicating if the mount is present.
    /// - Note: This function uses a combination of `df` and `grep` to check if the source is mounted.
    func isMounted() async -> Bool {
        // `df` returns a list of mounted filesystems. We need to construct
        // the name we'll be searching for in the first column (source):
        let filesystem_column_name: String
        do {
            filesystem_column_name = try SSHFS.makeRemoteConnectionString(
                self.snapshot,
                is_sshfs: true
            )
        } catch {
            filesystem_column_name = ""
        }
        
        // Format and run the commands:
        let df = await Command.run(Config.Command.Paths.df, with: ["-P"])
        let filtered_df = df.output
            // Split the output into lines:
            .split(separator: "\n")
            // Remove the first line (header):
            .dropFirst()
            // Filter out empty lines:
            .compactMap { line -> (String, String)? in
                // Split the line into columns:
                let columns = line.split(separator: " ", omittingEmptySubsequences: true)
                
                // Check if the line has at least 6 columns:
                guard columns.count >= 6 else { return nil }
                
                // POSIX: 0=Filesystem, 5=Mountpoint
                return (String(columns[0]), String(columns[5]))
            }
        // Check if the first column (source) matches the source and the last column (target) matches the target:
        return filtered_df.contains { paths in
            return paths.0 == filesystem_column_name && paths.1 == self.snapshot.paths.target
        }
    }
    
    
    /// Checks if the mount is valid and a connection can be made successfully.
    /// - Throws: A descriptive error if the mount cannot connect.
    func testConnection() async throws {
        // Validate the paths and SSH properties, throwing errors if they are invalid:
        try await SSHFS.checkReady(self.snapshot)
    }
    
    
    /// Updates the mount snapshot with new data.
    func updateSnapshot(_ new_snapshot: MountSnapshot) async { self.snapshot = new_snapshot }
    
    
    // MARK: - State Management
    // These methods are used to interface with MountClient and update the state of the mount in the UI.
    @MainActor
    func updateState(to new_state: MountStateWrapper, for mount: MountData) {
        mount.state.status = new_state.status
        mount.state.error = new_state.error
    }
    
    @MainActor
    func mount(_ mount: MountData) async {
        self.updateState(to: MountStateWrapper(status: .connecting), for: mount)
        await self.updateSnapshot(mount.makeSnapshot())
        self.updateState(to: await self.doMount(), for: mount)
    }
    
    @MainActor
    func unmount(_ mount: MountData) async {
        self.updateState(to: MountStateWrapper(status: .disconnecting), for: mount)
        await self.updateSnapshot(mount.makeSnapshot())
        self.updateState(to: await self.doUnmount(), for: mount)
    }
    
    @MainActor
    /// Dismiss the error for the mount, setting it to nil and update the status based on whether the mount is still mounted.
    func dismissError(for mount: MountData) async {
        self.updateState(
            to: MountStateWrapper(
                status: await self.isMounted() ? .connected : .disconnected,
                error: nil
            ),
            for: mount
        )
    }
    
    
    
    
    // MARK: - Private Methods
    
    /// If the mount is stubborn, force unmount it.
    /// - Parameter completion: A closure that returns a boolean indicating if the unmount was successful
    /// - Returns: A boolean indicating if the unmount was successful.
    /// - Throws: A MountError if the unmount fails to exit.
    private func forceUnmount(completion: @escaping (Bool) -> Void) async throws {
        // Attempt to unmount the disk:
        if try await diskutilUnmount(path: self.snapshot.paths.target, forcefully: true) {
            completion(true)
            return
        }
        
        // TODO: Set up a timer to make sure force unmount is successful.
        
        // If we've reached this point, the timer failed somehow:
        throw MountError.unmount_timed_out
    }
    
    
    // MARK: - Mount State Handling
    /// If the mount failed, set the status to whether the mount is still mounted or not and report the error.
    private func failedMounting(because error: MountError) async -> MountStateWrapper {
        return MountStateWrapper(
            // If the mount is still mounted, set the status to connected, otherwise set it to disconnected:
            status: await self.isMounted() ? MountStatus.connected : MountStatus.disconnected,
            error: error
        )
    }
    
    /// If the mount was successful, set the status to connected.
    private func successfulMount() -> MountStateWrapper {
        return MountStateWrapper(status: .connected)
    }
    
    /// If the mount was successfully unmounted, set the status to disconnected.
    private func successfulUnmount() -> MountStateWrapper {
        return MountStateWrapper(status: .disconnected)
    }
}
