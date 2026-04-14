//
//  SambaMount+CredentialsValidation.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Foundation
import KeychainAccess

/// This extension adds methods to the SambaMount class for validating credentials and retrieving passwords from the Keychain.
extension SambaMount {
    
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
        // Host cannot be empty:
        guard !host.isEmpty else { throw ClientError.invalidHost }
        
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
    
    /// Retrieve the password for the specified mount data from the Keychain.
    /// - Parameter mountData: The mount data object containing host and user information.
    internal static func retrievePassword(for mountData: MountDataObject) async -> String? {
        // If there's no host configured, we can't look up a password:
        guard let hostData = mountData.host else {
            await logger("Skipping Keychain lookup — mount has no host configured", level: .debug)
            return nil
        }
        
        do {
            let keychain = Keychain(server: "smb://\(hostData.hostname)", protocolType: .smb)
            return try keychain.get(mountData.user)
        } catch {
            await logger("Keychain access failed for \(mountData.user)@\(hostData.hostname)", level: .debug)
            return nil
        }
    }
}
