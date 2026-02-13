//
//  SambaMount+MountInformation.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 13/2/2026.
//

import Subprocess
import Foundation

extension SambaMount {
    
    // MARK: - Mount Information
    /// Searches for a specific SMB mount in the system and returns its parsed information.
    /// - Parameters:
    ///   - user: The username used for the mount.
    ///   - host: The hostname or IP address of the server.
    ///   - share: The share name to check for.
    /// - Returns: A `ParsedSMBMount` if the mount is found.
    /// - Throws: `ClientError.notFound` if the mount is not found or unable to retrieve mount information.
    private static func parseSMBMount(
        user: String,
        host: String,
        share: String
    ) async throws -> ParsedSMBMount {
        let result = try await Subprocess.run(
            .name("mount"),
            output: .string(limit: 1_000_000)
        )
        
        // If the command failed, we can't reliably check mounts:
        guard let output = result.standardOutput, !output.isEmpty else {
            throw ClientError.notFound
        }
        
        // Filter for SMB mounts matching our host and share in one pass:
        guard let line = output
        .split(separator: "\n")
        .first(where: { line in
            
            // Must be an SMB mount:
            guard line.contains("smbfs") else { return false }
        
            // Extract source URL portion:
            guard let sourceRange = line.range(of: " on ") else { return false }
            let sourceURL = String(line[..<sourceRange.lowerBound])
            
            // Check if this mount matches our host and share:
            return sourceURL.contains("/\(share)") &&
                (sourceURL.contains("//\(host)/") || sourceURL.contains("\(user)@\(host)/"))
        }) else {
            throw ClientError.notFound
        }
        
        // Parse the matched line:
        guard let sourceRange = line.range(of: " on "),
              let parenRange = line.range(of: " (") else {
            throw ClientError.notFound
        }
        
        // Extract source URL and mount path:
        let sourceURL = String(line[..<sourceRange.lowerBound])
        let pathStart = line.index(sourceRange.upperBound, offsetBy: 0)
        let pathEnd = parenRange.lowerBound
        let mountPath = String(line[pathStart..<pathEnd]).trimmingCharacters(in: .whitespaces)
        
        return ParsedSMBMount(
            sourceURL: sourceURL,
            mountPath: mountPath,
            fullLine: line
        )
    }

    /// Checks if a mount is currently active in the system.
    /// - Parameters:
    ///   - user: The username used for the mount.
    ///   - host: The hostname or IP address of the server.
    ///   - share: The share name to check for.
    /// - Throws: `ClientError.notFound` if the mount is not found.
    static func checkForMountInSystem(
        user: String,
        host: String,
        share: String
    ) async throws {
        _ = try await parseSMBMount(user: user, host: host, share: share)
    }

    /// Retrieves the mount path for a specific mount.
    /// - Parameters:
    ///   - user: The username used for the mount.
    ///   - host: The hostname or IP address of the server.
    ///   - share: The share name to check for.
    /// - Returns: The mount path (e.g., `/Volumes/share`).
    /// - Throws: `ClientError.notFound` if the mount is not found.
    static func getMountPath(
        user: String,
        host: String,
        share: String
    ) async throws -> String {
        let mount = try await parseSMBMount(user: user, host: host, share: share)
        return mount.mountPath
    }
}
