//
//  ReconnectPolicy.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 2/3/2026.
//

import CoreWLAN
import Network

/// Utilities for checking whether current network conditions permit an auto-reconnect attempt.
enum ReconnectPolicy {
    
    // MARK: - WiFi Trust
    /// Returns the SSID of the currently connected WiFi network, or nil if not on WiFi.
    static func currentSSID() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }

    /// Returns all SSIDs in macOS's preferred (auto-join) network list.
    static func preferredSSIDs() -> [String] {
        guard let profiles = CWWiFiClient.shared().interface()?.configuration()?.networkProfiles else {
            return []
        }
        return profiles.compactMap { ($0 as? CWNetworkProfile)?.ssid }
    }

    /// Returns true if the current WiFi network is in macOS's preferred (auto-join) network list.
    /// Returns false if not on WiFi or no preferred networks are found.
    static func isOnPreferredNetwork() -> Bool {
        guard let ssid = self.currentSSID() else { return false }
        return self.preferredSSIDs().contains(ssid)
    }
    
    
    // MARK: - Primary Eligibility Check
    /// Returns true if current network conditions allow a reconnect attempt, logging the reason if not.
    /// - Parameters:
    ///   - path: The current NWPath to inspect for interface type and constraints.
    static func isEligible(path: NWPath?) async -> Bool {
        guard let path = path else {
            logger("Skipping reconnect — no network path available.", level: .info)
            return false
        }
        // Cellular check:
        if path.usesInterfaceType(.cellular), !Config.Connection.Reconnection.allowOverCellular {
            logger("Skipping reconnect — on cellular and allowOverCellular is disabled.", level: .info)
            return false
        }

        // Low data mode check:
        if path.isConstrained, !Config.Connection.Reconnection.allowOnLowDataMode {
            logger("Skipping reconnect — low data mode is active and allowOnLowDataMode is disabled.", level: .info)
            return false
        }

        // Untrusted WiFi check:
        if path.usesInterfaceType(.wifi), !Config.Connection.Reconnection.allowUntrustedWifi, !isOnPreferredNetwork() {
            let ssid = currentSSID() ?? "unknown"
            logger("Skipping reconnect — WiFi '\(ssid)' is not a trusted (preferred) network.", level: .info)
            return false
        }

        return true
    }
}
