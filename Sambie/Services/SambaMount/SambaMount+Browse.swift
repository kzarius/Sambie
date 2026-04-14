//
//  SambaMount+Browse.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 9/3/2026.
//

import Subprocess
import Foundation

extension SambaMount {
    
    /// Lists available shares on the given server using `smbutil view`.
    /// - Parameters:
    ///   - host: The hostname or IP address of
    ///   - username: Optional username for authenticated servers
    ///   - password: Optional password for authenticated servers
    /// - Returns: An array of share name strings.
    /// - Throws: `ConfigurationError.processFailed` if the command fails.
    static func listShares(
        at host: String,
        username: String? = nil,
        password: String? = nil
    ) async throws -> [String] {
        // Construct the target URL for `smbutil`:
        let target = await SambaURL.create(
            hostname: host,
            username: username,
            password: password
        ).absoluteString

        // Use `-N` to avoid interactive password prompts when no password is provided:
        var arguments = ["view"]
        if password == nil || password?.isEmpty == true {
            arguments.append("-N")
        }
        arguments.append(target)

        // Run detached so the calling actor/thread is not blocked:
        return try await Task.detached(priority: .userInitiated) {
            let result = try await Subprocess.run(
                .name("smbutil"),
                arguments: Subprocess.Arguments(arguments),
                output: .string(limit: 1_000_000),
                error: .discarded
            )

            guard let output = result.standardOutput, !output.isEmpty else {
                throw ConfigurationError.processFailed(
                    process: "smbutil",
                    reason: "No output returned for \(host)"
                )
            }

            return Self.parseShares(from: output)
        }.value
    }
    
    
    // MARK: - Private Helpers
    /// Parses share names from `smbutil view` output, returning only Disk shares.
    private static func parseShares(from output: String) -> [String] {
        output
            // Split by line:
            .split(separator: "\n")
            // Skip "Share / Type / Comments" header and separator line
            .dropFirst(2)
            .compactMap { line -> String? in
                // Split on whitespace runs to handle variable spacing:
                let parts = line
                    .split(separator: " ")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                // Break into name and type:
                guard parts.count >= 2 else { return nil }
                let name = parts[0]
                let type = parts[1]
                
                // Only return shares of type "Disk":
                guard type == "Disk" else { return nil }
                return name
            }
    }
}
