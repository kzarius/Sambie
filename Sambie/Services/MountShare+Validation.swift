//
//  MountShare+Validation.swift
//  Sambie
//
//  URL validation utilities for SMB shares.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Foundation

extension MountShare {
    
    // MARK: - Methods
    /// Validates the core mount fields directly (not from URL).
    static func validateFields(
        user: String,
        host: String,
        share: String
    ) throws {
        // Host validation:
        guard !host.isEmpty else {
            throw ConfigurationError.invalidURL(reason: "Host cannot be empty.")
        }
        
        guard isValidHost(host) else {
            throw ConfigurationError.invalidURL(reason: "Host contains invalid characters.")
        }
        
        // Share validation:
        guard !share.isEmpty else {
            throw ConfigurationError.invalidURL(reason: "Share cannot be empty.")
        }
        
        guard isValidShareName(share) else {
            throw ConfigurationError.invalidURL(reason: "Share name contains invalid characters.")
        }
        
        // Username validation (can be empty for guest):
        guard isValidUsername(user) else {
            throw ConfigurationError.invalidURL(reason: "Username contains invalid characters.")
        }
    }
    
    /// Validates that a username doesn't contain invalid characters.
    /// Usernames cannot contain: @ / \ : * ? " < > |
    static func isValidUsername(_ user: String) -> Bool {
        // Empty username is valid (guest access):
        if user.isEmpty { return true }
        
        let invalidCharacters = CharacterSet(charactersIn: "@/\\:*?\"<>|")
        
        return user.unicodeScalars.allSatisfy { !invalidCharacters.contains($0) }
    }

    /// Validates that a host string is a valid IP address, hostname, or FQDN.
    static func isValidHost(_ host: String) -> Bool {
        // Check for obviously invalid patterns:
        if host.contains("//") || host.contains("@") { return false }
        
        // Host should only contain alphanumerics, dots, hyphens, and colons (for IPv6):
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: ".-:"))
        
        return host.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    /// Validates that a share name doesn't contain invalid SMB characters.
    /// SMB share names cannot contain: \ / : * ? " < > |
    static func isValidShareName(_ share: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return share.unicodeScalars.allSatisfy { !invalidCharacters.contains($0) }
    }
}
