//
//  ReconnectPolicy.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 2/3/2026.
//

import Subprocess
import CoreWLAN
import Network

/// Utilities for checking whether current network conditions permit an auto-reconnect attempt.
enum ReconnectPolicy {
    
    // MARK: - Ethernet Detection
    /// Returns true if the current path is using a wired ethernet interface.
    static func isOnEthernet(path: NWPath) -> Bool {
        path.usesInterfaceType(.wiredEthernet)
    }
    
    // MARK: - VPN Detection
    /// Checks if any active route is assigned to a utun interface, which indicates an active VPN connection.
    static func isVPNRouteActive() async -> Bool {
        // Gather the routing table (r) as numeric addresses (n):
        let result = try? await Subprocess.run(
            .name("netstat"),
            arguments: ["-rn"],
            output: .string(limit: 100_000),
        )
        guard let output = result?.standardOutput else { return false }
        
        // Chop into lines and check if any default-style route is assigned to a utun interface:
        return output.components(separatedBy: .newlines).contains { line in
            let lowerLine = line.lowercased()
            return (lowerLine.contains("default") || lowerLine.contains("0/1")) && lowerLine.contains("utun")
        }
    }


    // MARK: - Hotspot Detection
    /// Returns true if the default gateway matches a known iPhone or Android hotspot subnet.
    static func isOnHotspot(path: NWPath) async -> Bool {
        // Hotspots will be marked as "expensive" connections:
        guard path.isExpensive else {
            logger("ReconnectPolicy: isOnHotspot — exiting early because isExpensive is false", level: .debug)
            return false
        }
        
        // Check against the two common Hotspot gateways:
        guard let gateway = await self.defaultGateway() else { return false }
        return Config.Connection.hotspotGatewayPrefixes.contains(where: { gateway.hasPrefix($0) })
    }
    
    /// Runs `route -n get default` and returns the gateway IP, or nil on failure.
    static func defaultGateway() async -> String? {
        do {
            let result = try await Subprocess.run(
                .name("sh"),
                arguments: [
                    "-c",
                    "route -n get default 2>/dev/null | awk '/gateway:/ {print $2}'"
                ],
                output: .string(limit: 1_000),
                error: .discarded
            )
            
            guard let output = result.standardOutput, !output.isEmpty else {
                logger("ReconnectPolicy: defaultGateway — no output from route command.", level: .debug)
                return nil
            }
            let gateway = output.trimmingCharacters(in: .whitespacesAndNewlines)
            
            logger("ReconnectPolicy: defaultGateway — detected gateway: '\(gateway)'", level: .debug)
            return gateway
        } catch {
            logger("ReconnectPolicy: defaultGateway — subprocess failed: \(error)", level: .debug)
            return nil
        }
    }
    
    
    // MARK: - WiFi Trust
    /// Returns the security type string for the current WiFi interface, or nil if not on WiFi.
    static func getWifiSecurity(path: NWPath) async -> String? {
        // Check if we're on WiFi:
        if !path.usesInterfaceType(.wifi) { return nil }
        
        // Get the main interface's name and get it's info from `ipconfig`:
        guard let interfaceName = path.availableInterfaces.first?.name else { return nil }
        let result = try? await Subprocess.run(
            .name("ipconfig"),
            arguments: ["getsummary", interfaceName],
            output: .string(limit: 10_000),
            error: .discarded
        )
        guard let output = result?.standardOutput else { return nil }
        
        // Look for the line: "  Security : <type>"
        return output.components(separatedBy: .newlines)
            .first { $0.contains("Security :") }?
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// Returns true if the current WiFi network uses a security type in the trusted list (e.g. WPA2, WPA3).
    static func isWifiProtected(path: NWPath) async -> Bool {
        // Gather the WiFi security type:
        guard let security = await self.getWifiSecurity(path: path) else {
            logger("ReconnectPolicy: isWifiProtected — could not determine WiFi security type.", level: .debug)
            return false
        }
        
        // Check if it's in the trusted types list:
        return Config.Connection.Reconnection.secureWifiTypes.contains(where: { security.contains($0) })
    }
    
    
    // MARK: - Primary Eligibility Check
    /// Returns true if current network conditions allow a reconnect attempt, logging the reason if not.
    /// - Parameters:
    ///   - path: The current NWPath to inspect for interface type and constraints.
    ///   - settings: The user's reconnection settings to check against current network conditions.
    static func isEligible(path: NWPath?) async -> Bool {
        guard let path = path else {
            logger("Skipping reconnect — No network path available.", level: .info)
            return false
        }
        
        // Diagnostic dump:
        logger("""
            ReconnectPolicy: isEligible diagnostics —
              path.status:          \(path.status)
              isExpensive:          \(path.isExpensive)
              isConstrained:        \(path.isConstrained)
              usesWifi:             \(path.usesInterfaceType(.wifi))
              usesEthernet:         \(path.usesInterfaceType(.wiredEthernet))
              security:             \(await self.getWifiSecurity(path: path) ?? "unknown")
              VPN:                  \(await self.isVPNRouteActive() ? "active" : "inactive")
            """, level: .debug)
        
        // Ethernet bypass — always trust ethernet if the setting is enabled:
        if Settings.Reconnection.alwaysTrustEthernet, self.isOnEthernet(path: path) {
            logger("Reconnecting – Always trusting ethernet networks.", level: .info)
            return true
        }
        
        // Hotspot check — isExpensive + gateway matches known hotspot subnet:
        if !Settings.Reconnection.allowOverHotspot, await self.isOnHotspot(path: path) {
            logger("Skipping reconnect — On hotspot and allowOverHotspot is disabled.", level: .info)
            return false
        }

        // Low data mode check:
        if !Settings.Reconnection.allowOnLowDataMode, path.isConstrained {
            logger("Skipping reconnect — low data mode is active and allowOnLowDataMode is disabled.", level: .info)
            return false
        }
        
        // VPN check — any active route on a utun interface indicates an active VPN connection:
        if !Settings.Reconnection.allowOnVPN, await self.isVPNRouteActive() {
            logger("Skipping reconnect — active VPN route detected and allowOnVPN is disabled.", level: .info)
            return false
        }
        
        // WiFi trust check — only reconnect on password-protected WiFi:
        if path.usesInterfaceType(.wifi), Settings.Reconnection.trustSecureWifi {
            guard await self.isWifiProtected(path: path) else {
                logger("Skipping reconnect — WiFi network is not protected (WPA2/WPA3).", level: .info)
                return false
            }
        }

        return true
    }
}
