//
//  SettingsView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 4/3/2026.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties
    @AppStorage("reconnection.alwaysTrustEthernet") private var alwaysTrustEthernet = Config.Connection.Reconnection.alwaysTrustEthernet
    @AppStorage("reconnection.allowOverHotspot")    private var allowOverHotspot     = Config.Connection.Reconnection.allowOverHotspot
    @AppStorage("reconnection.allowOnLowDataMode")  private var allowOnLowDataMode   = Config.Connection.Reconnection.allowOnLowDataMode
    @AppStorage("reconnection.allowOnVPN")          private var allowOnVPN           = Config.Connection.Reconnection.allowOnVPN
    @AppStorage("reconnection.trustSecureWifi")     private var trustSecureWifi      = Config.Connection.Reconnection.trustSecureWifi


    // MARK: - View
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 26) {
                self.reconnectionBlock
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 480, height: 480)
    }


    // MARK: - Blocks
    private var reconnectionBlock: some View {
        SettingsFormBlock(label: "Auto-Reconnect", icon: "arrow.trianglehead.2.clockwise") {
            VStack(alignment: .leading, spacing: 12) {

                // Spacer between block title and first option:
                Spacer().frame(height: 4)

                SettingsToggleRow(
                    title: "Trust Ethernet Networks",
                    description: (
                        on:  "Always reconnecting over wired Ethernet, ignoring all other checks.",
                        off: "Ethernet connections are subject to the same checks as other network types."
                    ),
                    isOn: self.$alwaysTrustEthernet
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow over Hotspots",
                    description: (
                        on:  "Reconnecting when tethered to a mobile hotspot.",
                        off: "Hotspot connections will be skipped."
                    ),
                    isOn: self.$allowOverHotspot
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow on Low Data Mode",
                    description: (
                        on:  "Reconnecting even on networks with Low Data Mode enabled.",
                        off: "Networks marked as Low Data Mode will be skipped."
                    ),
                    isOn: self.$allowOnLowDataMode
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow over VPN",
                    description: (
                        on:  "Reconnecting when an active VPN is detected.",
                        off: "No reconnection attempts will be made while a VPN is active."
                    ),
                    isOn: self.$allowOnVPN
                )

                Divider()

                SettingsToggleRow(
                    title: "Secure WiFi Only",
                    description: (
                        on:  "Only reconnecting on password-protected networks (WPA2/WPA3).",
                        off: "Reconnecting on any available WiFi network, including open ones."
                    ),
                    isOn: self.$trustSecureWifi
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
