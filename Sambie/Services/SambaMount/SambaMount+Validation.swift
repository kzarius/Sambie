//
//  MountShare+Validation.swift
//  Sambie
//
//  URL validation utilities for SMB shares.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Subprocess
import Foundation

extension SambaMount {
    
    // MARK: - Credentials Validation
    /// Validates that a username doesn't contain invalid characters.
    /// Usernames cannot contain: @ / \ : * ? " < > |
    static func validateUsername(_ user: String) throws {
        // Empty username is valid (guest access):
        if user.isEmpty { return }
        
        let invalidCharacters = CharacterSet(charactersIn: "@/\\:*?\"<>|")
        
        if !user.unicodeScalars.allSatisfy({ !invalidCharacters.contains($0) }) {
            throw ClientError.invalidUsername
        }
    }

    /// Validates that a host string is a valid IP address, hostname, or FQDN.
    static func validateHost(_ host: String) throws {
        // Check for obviously invalid patterns:
        if host.contains("//") || host.contains("@") { throw ClientError.invalidHost }
        
        // Host should only contain alphanumerics, dots, hyphens, and colons (for IPv6):
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: ".-:"))

        if !host.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            throw ClientError.invalidHost
        }
    }

    /// Validates that a share name doesn't contain invalid SMB characters.
    /// SMB share names cannot contain: \ / : * ? " < > |
    static func validateShareName(_ share: String) throws {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        if !share.unicodeScalars.allSatisfy({ !invalidCharacters.contains($0) }) {
            throw ClientError.invalidShareName
        }
    }
    
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
    ///  - Throws: ConnectionError.portClosed if the port is not accessible.
    /// Verify the specified port is accessible on the host.
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
                process: "host",
                reason: error.localizedDescription
            )
        }
    }
}
