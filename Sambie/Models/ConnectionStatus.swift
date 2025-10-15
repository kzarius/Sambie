//
//  ConnectionStatus.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/15/25.
//

/// Statuses available for mounts. This is used to determine what the mount is currently doing.
enum ConnectionStatus: String, Equatable, Codable {
    case disconnecting = "Disconnecting"
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
}
