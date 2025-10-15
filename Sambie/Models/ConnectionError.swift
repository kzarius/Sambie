//
//  ConnectionError.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/15/25.
//

import Foundation

enum ConnectionError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Cases
    case mount_exists(path: String)
    case mount_failed
    case unmount_failed
    case unmount_timed_out
    case already_mounted(path: String)
    case connection_refused
    case connection_timed_out
    case hostname_unresolvable
    case unreachable
    case remote_host_disconnected
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
        case .mount_exists(let path):
            return "A mount already exists at the specified path: \"\(path)\"."
        case .mount_failed:
            return "Failed to mount the specified source."
        case .unmount_failed:
            return "Failed to unmount the specified target."
        case .unmount_timed_out:
            return "The unmount operation timed out."
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
        case .remote_host_disconnected:
            return "The remote host has disconnected."
        }
    }
}
