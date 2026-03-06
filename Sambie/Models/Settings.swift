//
//  Settings.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/3/2026.
//

import Foundation

/// Application settings and user preferences.
enum Settings {

    // MARK: - Keys
    private enum Keys {
        static let alwaysTrustEthernet =    "reconnection.alwaysTrustEthernet"
        static let allowOverHotspot =       "reconnection.allowOverHotspot"
        static let allowOnLowDataMode =     "reconnection.allowOnLowDataMode"
        static let allowOnVPN =             "reconnection.allowOnVPN"
        static let trustSecureWifi =        "reconnection.trustSecureWifi"
    }

    // MARK: - Reconnection
    enum Reconnection {
        static var alwaysTrustEthernet: Bool {
            get { UserDefaults.standard.object(forKey: Keys.alwaysTrustEthernet) as? Bool ?? Config.Connection.Reconnection.alwaysTrustEthernet }
            set { UserDefaults.standard.set(newValue, forKey: Keys.alwaysTrustEthernet) }
        }
        
        static var allowOverHotspot: Bool {
            get { UserDefaults.standard.object(forKey: Keys.allowOverHotspot) as? Bool ?? Config.Connection.Reconnection.allowOverHotspot }
            set { UserDefaults.standard.set(newValue, forKey: Keys.allowOverHotspot) }
        }

        static var allowOnLowDataMode: Bool {
            get { UserDefaults.standard.object(forKey: Keys.allowOnLowDataMode) as? Bool ?? Config.Connection.Reconnection.allowOnLowDataMode }
            set { UserDefaults.standard.set(newValue, forKey: Keys.allowOnLowDataMode) }
        }

        static var allowOnVPN: Bool {
            get { UserDefaults.standard.object(forKey: Keys.allowOnVPN) as? Bool ?? Config.Connection.Reconnection.allowOnVPN }
            set { UserDefaults.standard.set(newValue, forKey: Keys.allowOnVPN) }
        }
        
        static var trustSecureWifi: Bool {
            get { UserDefaults.standard.object(forKey: Keys.trustSecureWifi) as? Bool ?? Config.Connection.Reconnection.trustSecureWifi }
            set { UserDefaults.standard.set(newValue, forKey: Keys.trustSecureWifi) }
        }
    }
}
