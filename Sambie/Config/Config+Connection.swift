//
//  Config+Connection.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//

import SwiftUI

/// Connection Configuration.
extension Config {
    
    enum Connection {
        nonisolated static let checkMountInterval = 10.0 // Interval for checking the mount status and updating the UI.
        static let mountTimeout = 15.0 // Seconds before a server is considered unreachable and zombie unmount is triggered.
        static let hotspotGatewayPrefixes = ["172.20.10.1", "192.168.43.1"] // Known hotspot gateway prefixes: iPhone (172.20.10.x) and Android (192.168.43.x).
        static let connectTimeout = 15.0 // Seconds before a connection attempt is considered failed.
        
        enum Reconnection {
            static let baseDelay = 5.0 // Seconds that we start our reconnection attempts with.
            static let maxMinutesDelay = 5.0 // Maximum delay between reconnection attempts in minutes.
            static let maxReconnectAttempts = 5
            static let initialReconnectDelay = 5.0
            static let maxReconnectDelay = 300.0
            static let secureWifiTypes = ["WPA2", "WPA3"] // Wi-Fi security types considered secure for auto-reconnect purposes.
            
            // User-managable:
            nonisolated static let alwaysTrustEthernet = true
            nonisolated static let allowOverHotspot = true
            nonisolated static let allowOnLowDataMode = true
            nonisolated static let allowOnVPN = true
            nonisolated static let trustSecureWifi = true
        }
    }
}
