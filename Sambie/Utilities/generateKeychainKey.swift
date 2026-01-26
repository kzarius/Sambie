//
//  generateKeychainKey.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 23/1/2026.
//

import Foundation

/// Helper to generate the keychain key for a mount password.
func generateKeychainKey(for mountID: UUID) -> String {
    return "mount-\(mountID)-password"
}
