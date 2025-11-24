//
//  ConnectionError.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/15/25.
//

import Foundation

enum ConnectionError: Error, LocalizedError, Hashable, Codable {
    
    // MARK: - Errors
    case connectionRefused
    case connectionTimedOut
    case hostnameUnresolvable
    case portClosed(port: Int)
    case unreachable(host: String)
    case remoteHostDisconnected
    
    
    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
        case .connectionRefused:
            return "Connection refused. Please check the remote server."
        case .connectionTimedOut:
            return "Connection timed out. Please check your network connection."
        case .hostnameUnresolvable:
            return "The hostname could not be resolved. Please check the hostname."
        case .portClosed(let port):
            return "The port \(port) is closed on the remote server."
        case .unreachable(let host):
            return "The remote server '\(host)' is unreachable. Please check your network connection."
        case .remoteHostDisconnected:
            return "The remote host has disconnected."
        }
    }
}
