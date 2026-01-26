//
//  MountErrors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/26/25.
//

import Foundation

/// Errors for static validation issues (invalid URLs, missing parameters, wrong port numbers, etc.) that can be detected before attempting a connection.
enum ConfigurationError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Errors
    case invalidMacVersion
    case missingRequired(parameter: String)
    case processFailed(process: String, reason: String)
    case unableToEdit(reason: String)
    case keychainUnaccessible(reason: String)
    
    /// Samba URL parsing:
    case invalidURL(reason: String?)
    case missingHost
    case missingShare
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
        case .processFailed(let process, let reason):
            return "The process \"\(process)\" failed: \(reason)"
        case .unableToEdit(let reason):
            return "Unable to edit configuration: \(reason)"
        case .keychainUnaccessible(let reason):
            return "The Keychain is not accessible: \(reason)"
            
        /// Errors that can occur when parsing Samba URL strings:
        case .invalidURL(let reason):
            return "The provided URL is invalid: \(reason ?? "Malformed URL.")"
        case .missingHost:
            return "The URL is missing a required host."
        case .missingShare:
            return "The URL is missing a required share name."
        case .invalidScheme:
            return "The URL scheme must be 'smb'."
        case .invalidPort(let port):
            return "The specified port \(port) is invalid."
        }
    }
}
