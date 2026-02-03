//
//  SambaURL.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/1/2026.
//

import Foundation

/// A utility for parsing and generating Samba URL strings.
struct SambaURL {

    /// Parses a Samba URL string into its components.
    /// - Parameter urlString: The URL string to parse (e.g., "smb://user@host/share").
    /// - Returns: A tuple containing the user, host, and share.
    /// - Throws: A `ConfigurationError` if the URL is malformed or missing components.
    static func parse(urlString: String) throws -> (user: String, host: String, share: String) {
        guard var components = URLComponents(string: urlString) else {
            throw ConfigurationError.invalidURL(reason: "This URL seems to be malformed.")
        }

        // If no scheme is provided, assume 'smb'.
        if components.scheme == nil {
            components.scheme = "smb"
        }

        guard components.scheme?.lowercased() == "smb" else {
            throw ConfigurationError.invalidScheme
        }

        guard let host = components.host, !host.isEmpty else {
            throw ConfigurationError.missingHost
        }

        // The path is the share name; remove the leading slash.
        let share = String(components.path.dropFirst())

        guard !share.isEmpty else {
            throw ConfigurationError.missingShare
        }

        let user = components.user ?? ""

        return (user, host, share)
    }
    
    /// Parses a Samba URL from a URL object.
    static func parse(url: URL) throws -> (user: String, host: String, share: String) {
        return try parse(urlString: url.absoluteString)
    }
    
    /// Creates a Samba URL string from a Mount object.
    /// - Parameter mount: The mount object containing the host, share, and user.
    /// - Returns: A formatted Samba URL string.
    static func create(from mountData: MountDataObject) -> URL {
        var components = URLComponents()
        components.scheme = "smb"
        components.host = mountData.host
        components.path = "/" + mountData.share

        if !mountData.user.isEmpty {
            components.user = mountData.user
        }

        return components.url ?? URL(fileURLWithPath: "")
    }
}
