//
//  MountErrors.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/26/25.
//

import Foundation

enum GeneralError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - General Errors
    case invalid_mac_version
    case missing_required(parameter: String)
    
    case mount_exists(path: String)
    case mount_failed
    case unmount_failed
    case unmount_timed_out
    
    case permission_denied
    
    /// Mount configuration errors:
    case name_not_unique(name: String)
    case internal_mount_error
    case target_not_unique(path: String)
    
    /// Errors that can occur when running a shell command:
    case io_error
    case command_failed(command: String, reason: String? = nil)
    
    /// Errors that can occur when checking the status of the source:
    case already_mounted(path: String)
    case connection_refused
    case connection_timed_out
    case hostname_unresolvable
    case unreachable
    
    /// Other errors:
    case remote_host_disconnected
    case db_error
    case not_found
    case unknown(code: Int32? = nil, output: String? = nil)
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
            
        /// General errors:
        case .invalid_mac_version:
            return "This version of macOS is not supported. Please update to a newer version."
        case .missing_required(let parameter):
            return "The required parameter \"\(parameter)\" is missing."
        case .mount_exists(let path):
            return "A mount already exists at the specified path: \"\(path)\"."
        case .mount_failed:
            return "Failed to mount the specified source."
        case .unmount_failed:
            return "Failed to unmount the specified target."
        case .unmount_timed_out:
            return "The unmount operation timed out."
        case .permission_denied:
            return "Permission denied - you do not have the necessary permissions."
            
        /// Mount configuration errors:
        case .name_not_unique(let name):
            return "The mount name \"\(name)\" is already in use. Please choose a different name."
        case .internal_mount_error:
            return "An internal error occurred while querying the mount."
        case .target_not_unique(let path):
            return "The target path \"\(path)\" is already in use by another mount. Please choose a different path."
            
        /// Errors that can occur when running a shell command:
        case .io_error:
            return "An input/output error occurred while running the command."
        case .command_failed(let command, let reason):
            let reason_string = (reason != nil) ? "`\(reason!)`" : ""
            return "The command `\(command)` failed to execute successfully. \(reason_string)"
            
        /// Errors that can occur when checking the status of the source:
        case .already_mounted(let path):
            return "The specified path \"\(path)\" is already mounted."
        case .connection_refused:
            return "Connection refused. Please check the remote server."
        case .connection_timed_out:
            return "Connection timed out. Please check your network connection."
        case .hostname_unresolvable:
            return "The hostname could not be resolved. Please check the hostname."
        case .unreachable:
            return "The remote server is unreachable. Please check your network connection."
            
        /// Other errors:
        case .remote_host_disconnected:
            return "The remote host has disconnected."
        case .db_error:
            return "An error occurred while accessing the database."
        case .not_found:
            return "The specified mount was not found."
        case .unknown(let code, let output):
            let code_string = (code != nil) ? " (Code: \(code!))" : ""
            let output_string = (output != nil) ? " (Output: \(output!))" : ""
            return "An unknown error occurred. Code: \(code_string)\(output_string)"
        }
    }
}
