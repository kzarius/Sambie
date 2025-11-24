//
//  MountErrors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/26/25.
//

import Foundation

enum ClientError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Errors
    /// Mounting errors:
    case mountExists(path: String)
    case mountFailed
    case unmountFailed
    case unmountTimedOut
    case alreadyMounted(path: String)
    case permissionDenied
    case invalidMount
    case notFound
    
    /// Mountpoint errors:
    case mountpointUnavailable(mountpoint: String)
    case mountpointNotDirectory(mountpoint: String)
    case mountpointNotWritable(mountpoint: String)
    case mountpointDoesNotExist
    case multipleMountPointsFound
    
    /// Other errors:
    case dbError
    case unknown(code: Int32? = nil, output: String? = nil)
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
            
        /// Mounting errors:
        case .mountExists(let path):
            return "A mount already exists at the specified path: \"\(path)\"."
        case .mountFailed:
            return "Failed to mount the specified source."
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
        case .notFound:
            return "The specified mount was not found."
            
        /// Mountpoint errors:
        case .mountpointUnavailable(let mountpoint):
            return "The mountpoint \"\(mountpoint)\" is unavailable."
        case .mountpointNotDirectory(let mountpoint):
            return "The mountpoint \"\(mountpoint)\" is not a directory."
        case .mountpointNotWritable(let mountpoint):
            return "The mountpoint \"\(mountpoint)\" is not writable."
        case .mountpointDoesNotExist:
            return "The mountpoint could not be found."
        case .multipleMountPointsFound:
            return "Multiple mountpoints were found when only one was expected."
            
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
