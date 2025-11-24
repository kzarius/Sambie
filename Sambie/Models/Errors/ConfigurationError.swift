//
//  MountErrors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/26/25.
//

import Foundation

enum ConfigurationError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Errors
    case invalidMacVersion
    case missingRequired(parameter: String)
    
    /// Samba URL parsing:
    case invalidURL(reason: String?)
    case missingHost
    case invalidScheme
    case invalidPort(port: Int)
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
            
            /// General errors:
        case .invalidMacVersion:
            return "This version of macOS is not supported. Please update to a newer version."
        case .missingRequired(let parameter):
            return "The required parameter \"\(parameter)\" is missing."
            
            /// Errors that can occur when parsing Samba URL strings:
        case .invalidURL(let reason):
            return "The provided URL is invalid: \(reason ?? "")"
        case .missingHost:
            return "The URL is missing a required host."
        case .invalidScheme:
            return "The URL scheme must be 'smb'."
        case .invalidPort(let port):
            return "The specified port \(port) is invalid."
        }
    }
}
