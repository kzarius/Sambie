//
//  MountShare+URLParsing.swift
//  Sambie
//
//  URL parsing and building utilities for SMB shares.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Foundation

extension MountShare {
    
    // MARK: - Public Methods
    /// Builds a Samba URL from a Mount object.
    static func buildURL(from mount: Mount) -> String {
        return buildURL(
            user: mount.user,
            host: mount.host,
            share: mount.share
        )
    }
    
    /// Builds a Samba URL from the given fields.
    static func buildURL(
        user: String? = nil,
        host: String,
        share: String
    ) -> String {
        let prefix = "smb://"
        
        if let user = user, user != "" {
            return prefix + user + "@" + host + "/" + share
        } else {
            return prefix + host + "/" + share
        }
    }
    
    /// Parses a Samba URL and returns the extracted components.
    static func parseURL(_ urlString: String) throws -> (
        user: String?,
        host: String,
        share: String
    ) {
        var cleanURL = urlString
                
        // Remove smb:// prefix if present:
        if cleanURL.lowercased().hasPrefix("smb://") {
            cleanURL = String(cleanURL.dropFirst(6))
        }
        
        // URL cannot be empty after removing prefix:
        guard !cleanURL.isEmpty else {
            throw ConfigurationError.invalidURL(reason: "URL cannot be empty.")
        }
        
        // Split by @ to separate username from host/share:
        let parts = cleanURL.split(separator: "@", maxSplits: 1)
        
        if parts.count == 2 {
            let user = String(parts[0])
            
            guard isValidUsername(user) else {
                throw ConfigurationError.invalidURL(reason: "Username contains invalid characters.")
            }
            
            let hostShare = String(parts[1])
            let (host, share) = try parseHostAndShare(hostShare)
            
            return (user, host, share)
        } else {
            let (host, share) = try parseHostAndShare(cleanURL)
            return (nil, host, share)
        }
    }
    
    /// Parses the host and share portion of the URL.
    static func parseHostAndShare(_ hostShare: String) throws -> (
        host: String,
        share: String
    ) {
        let components = hostShare.split(separator: "/", maxSplits: 1)
        
        let host = String(components[0])
        
        guard !host.isEmpty else {
            throw ConfigurationError.invalidURL(reason: "Host cannot be empty.")
        }
        
        guard isValidHost(host) else {
            throw ConfigurationError.invalidURL(reason: "Host contains invalid characters.")
        }
        
        guard components.count > 1 else {
            throw ConfigurationError.invalidURL(reason: "Share is missing.")
        }
        
        let share = String(components[1])
        
        guard !share.isEmpty else {
            throw ConfigurationError.invalidURL(reason: "Share cannot be empty.")
        }
        
        guard isValidShareName(share) else {
            throw ConfigurationError.invalidURL(reason: "Share name contains invalid characters.")
        }
        
        return (host, share)
    }
}
