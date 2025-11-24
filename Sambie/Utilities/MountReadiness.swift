//
//  MountReadiness.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/22/25.
//

import Foundation
import Network

struct MountReadiness {
    
    // MARK: - Public Methods
    /// Checks if a Samba mount is ready to be connected
    static func checkMount(
        host: String,
        customMountPoint: URL? = nil
    ) async throws {
        // Step 1: Verify DNS resolution
        try await self.verifyHostResolvable(host: host)
        
        // Step 2: Verify SMB port accessibility
        try await self.checkPortAccessible(
            host: host,
            port: Config.Ports.samba
        )
        
        // Step 3: Verify mount point if custom one provided
        if let customMountPoint = customMountPoint {
            try self.checkMountPoint(customMountPoint)
        }
    }
    
    
    // MARK: - Private Methods
    /// Verify the host can be resolved via DNS using getaddrinfo.
    /// This performs pure DNS resolution without attempting any connections.
    private static func verifyHostResolvable(host: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue.global()
            
            // Perform DNS resolution asynchronously.
            // The queue.async approach is used here because getaddrinfo() is a blocking C function that doesn't have native Swift async support.
            queue.async {
                var hints = addrinfo()
                hints.ai_family = AF_UNSPEC // Allow both IPv4 and IPv6.
                hints.ai_socktype = SOCK_STREAM
                hints.ai_flags = AI_ADDRCONFIG // Only return addresses if we have connectivity.
                
                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(host, nil, &hints, &result)
                
                // Ensure we free the result when done:
                defer {
                    if let result = result {
                        freeaddrinfo(result)
                    }
                }
                
                switch status {
                    
                // DNS resolution successful:
                case 0:
                    continuation.resume()
                    
                // Hostname doesn't exist:
                case EAI_NONAME, EAI_NODATA:
                    continuation.resume(throwing: ConnectionError.unreachable(host: host))
                    
                // Other DNS errors (EAI_AGAIN, EAI_FAIL, etc.):
                default:
                    continuation.resume(throwing: ConnectionError.unreachable(host: host))
                }
            }
        }
    }
    
    /// Verify the specified port is accessible on the host.
    /// - Parameters:
    ///  - host: The hostname or IP address to check.
    ///  - port: The port number to check.
    ///  - timeout: The timeout duration for the connection attempt.
    ///  - Throws: ConnectionError.portClosed if the port is not accessible.
    /// Verify the specified port is accessible on the host.
    private static func checkPortAccessible(host: String, port: Int, timeout: TimeInterval = 5.0) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            
            // Validate port range:
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                continuation.resume(throwing: ConfigurationError.invalidPort(port: port))
                return
            }
            
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .tcp
            )
            
            // Use DispatchQueue for thread-safe flag:
            let syncQueue = DispatchQueue(label: "connection-sync")
            var hasResumed = false
            
            // Setup timeout task:
            let timeoutTask = Task {
                try await Task.sleep(for: .seconds(timeout))
                syncQueue.sync {
                    // Timeout reached, resume with error if not already done:
                    if !hasResumed {
                        hasResumed = true
                        connection.cancel()
                        continuation.resume(throwing: ConnectionError.portClosed(port: port))
                    }
                }
            }
            
            // Handle state updates:
            connection.stateUpdateHandler = { state in
                switch state {
                // Connection established:
                case .ready:
                    syncQueue.sync {
                        if !hasResumed {
                            hasResumed = true
                            timeoutTask.cancel()
                            connection.cancel()
                            continuation.resume()
                        }
                    }
                // Connection failed or closed:
                case .failed, .waiting, .cancelled:
                    syncQueue.sync {
                        if !hasResumed {
                            hasResumed = true
                            timeoutTask.cancel()
                            connection.cancel()
                            continuation.resume(throwing: ConnectionError.portClosed(port: port))
                        }
                    }
                    
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        }
    }
    
    /// Verify mount point exists and is accessible.
    private static func checkMountPoint(_ mountPoint: URL) throws {
        let fileManager = FileManager.default
        
        // Check if path exists:
        guard fileManager.fileExists(atPath: mountPoint.path) else {
            throw ClientError.mountpointUnavailable(mountpoint: mountPoint.path)
        }
        
        // Check if it's a directory:
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: mountPoint.path, isDirectory: &isDirectory)
        guard isDirectory.boolValue else {
            throw ClientError.mountpointNotDirectory(mountpoint: mountPoint.path)
        }
        
        // Check if it's writable:
        guard fileManager.isWritableFile(atPath: mountPoint.path) else {
            throw ClientError.mountpointNotWritable(mountpoint: mountPoint.path)
        }
    }
}
