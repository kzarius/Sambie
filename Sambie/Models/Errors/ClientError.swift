//
//  MountErrors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/26/25.
//

import Foundation

/// Errors related to mounting and unmounting Samba shares. Runtime errors that occur during actual mount operations (unreachable hosts, connection failures, unmount issues, etc.)
enum ClientError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Errors
    /// Mounting errors:
    case mountExists(path: String)
    case mountFailed(reason: String)
    case unmountFailed
    case unmountTimedOut
    case alreadyMounted(path: String)
    case permissionDenied
    case invalidMount
    case deleteDenied
    case notFound

    /// Samba credential errors:
    case invalidUsername
    case invalidHost
    case invalidShareName
    
    /// Other errors:
    case dbError
    case unknown(code: Int32? = nil, output: String? = nil)
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
            
        /// Mounting errors:
        case .mountExists(let path):
            return "A mount already exists at the specified path: \"\(path)\"."
        case .mountFailed(let reason):
            return "Failed to mount the specified source: \(reason)"
        case .unmountFailed:
            return "Failed to unmount the specified target."
        case .unmountTimedOut:
            return "The unmount operation timed out."
        case .alreadyMounted(let path):
            return "The specified path \"\(path)\" is already mounted."
        case .permissionDenied:
            return "Permission denied - you do not have the necessary permissions."
        case .invalidMount:
            return "The selected mount is invalid. It may have been deleted before the process could complete."
        case .deleteDenied:
            return "Delete denied - the mount cannot be deleted at this time."
        case .notFound:
            return "The specified mount was not found."
            
            /// Samba credential errors:
        case .invalidUsername:
            return "The provided username is invalid."
        case .invalidHost:
            return "The provided host is invalid."
        case .invalidShareName:
            return "The provided share name is invalid."
            
        /// Other errors:
        case .dbError:
            return "An error occurred while accessing the database."
        case .unknown(let code, let output):
            let codeString = (code != nil) ? " (Code: \(code!))" : ""
            let outputString = (output != nil) ? " (Output: \(output!))" : ""
            return "An unknown error occurred. Code: \(codeString)\(outputString)"
        }
    }
}
