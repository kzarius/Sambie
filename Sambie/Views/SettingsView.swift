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
        VStack(alignment: .leading, spacing: 26) {
            self.reconnectionBlock
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }


    // MARK: - Blocks
    private var reconnectionBlock: some View {
        EditorFormBlock(label: "Auto-Reconnect", icon: "arrow.trianglehead.2.clockwise") {
            VStack(alignment: .leading, spacing: 12) {

                // Spacer between block title and first option:
                Spacer().frame(height: 4)

                SettingsToggleRow(
                    title: "Always Trust Ethernet",
                    description: "Always reconnect when on a wired ethernet connection, ignoring all other checks.",
                    isOn: self.$alwaysTrustEthernet
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow over Hotspot",
                    description: "Reconnect when tethered to an iPhone or Android mobile hotspot.",
                    isOn: self.$allowOverHotspot
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow on Low Data Mode",
                    description: "Reconnect even when Low Data Mode is active.",
                    isOn: self.$allowOnLowDataMode
                )

                Divider()

                SettingsToggleRow(
                    title: "Allow over VPN",
                    description: "Reconnect when an active VPN connection is detected.",
                    isOn: self.$allowOnVPN
                )

                Divider()

                SettingsToggleRow(
                    title: "Only Reconnect on Secure WiFi",
                    description: "Only reconnect on password-protected WiFi networks (WPA2/WPA3). Open networks will be skipped.",
                    isOn: self.$trustSecureWifi
                )
            }
        }
    }
}
