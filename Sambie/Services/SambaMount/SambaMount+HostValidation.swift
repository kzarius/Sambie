//
//  SambaMount+HostValidation.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 13/2/2026.
//

import Network
import Subprocess
import Foundation

extension SambaMount {
    
    // MARK: - Host and Port Validation
    /// Verify the host can be resolved via DNS.
    /// This performs pure DNS resolution without attempting any connections.
    static func verifyHostResolvable(host: String) async throws {
        do {
            // Run the 'host' command to check DNS resolution:
            let result = try await Subprocess.run(
                .name("host"),
                arguments: [host],
                output: .discarded,
                error: .discarded
            )
            
            // If the termination status is not successful, DNS resolution failed:
            guard result.terminationStatus.isSuccess else {
                throw ConnectionError.unreachable(host: host)
            }
        } catch {
            throw ConfigurationError.processFailed(
                process: "host",
                reason: error.localizedDescription
            )
        }
    }
    
    /// Verify the specified port is accessible on the host.
    /// - Parameters:
    ///  - host: The hostname or IP address to check.
    ///  - port: The port number to check.
    ///  - timeout: The timeout duration for the connection attempt.
    ///  - Throws: `ConfigurationError.invalidPort` if the port number is out of range.
    ///  - Throws: `ConnectionError.portClosed` if the port is not accessible.
    ///  - Throws: `ConfigurationError.processFailed` if the check process itself fails.
    static func checkPortAccessible(
        host: String,
        port: Int,
        timeout: TimeInterval = 5.0
    ) async throws {
        // Validate port number:
        guard port > 0 && port <= 65535 else {
            throw ConfigurationError.invalidPort(port: port)
        }

        do {
            // Use 'nc' (netcat) to check port accessibility:
            let result = try await Subprocess.run(
                .name("nc"),
                arguments: [
                    "-z", // Scan mode (no data transfer)
                    "-G", String(Int(timeout)), // Timeout in seconds
                    host,
                    String(port)
                ],
                output: .discarded,
                error: .discarded
            )
            
            // If the termination status is not successful, the port is closed:
            guard result.terminationStatus.isSuccess else {
                throw ConnectionError.portClosed(port: port)
            }
        } catch {
            throw ConfigurationError.processFailed(
                process: "nc",
                reason: error.localizedDescription
            )
        }
    }
    
    /// Checks whether the server for a mounted share is still reachable on its configured port.
    /// - Parameter mountData: The mount data object containing host and port information.
    /// - Returns: `true` if the server is reachable, `false` otherwise.
    static func isServerReachable(mountData: MountDataObject) async -> Bool {
        do {
            try await checkPortAccessible(host: mountData.host, port: mountData.port)
            return true
        } catch {
            return false
        }
    }
}
