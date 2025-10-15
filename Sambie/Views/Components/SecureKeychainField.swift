//
//  SecureKeychainField.swift
//  Shell Mounts
//
//  This component provides a secure input field that does not initially reflect the character count of the secret, for editing KeychainEntry secrets.
//
//  Created by Kaeo McKeague-Clark on 9/19/25.
//

import SwiftUI

struct SecureKeychainField: View {
    @Binding var entry: KeychainEntry
    @FocusState private var is_focused: Bool
    private let preset_character_count = 8
    
    init(_ entry: Binding<KeychainEntry>) {
        self._entry = entry
    }
    
    var body: some View {
        SecureField("", text: Binding(
            // If the entry has changed or is empty, show the actual secret:
            get: {
                if self.entry.has_changed || self.is_focused {
                    return self.entry.secret
                } else {
                    return String(repeating: "•", count: self.preset_character_count)
                }
            },
            // On change, update the entry's secret and mark it as changed:
            set: { new_value in
                if !self.entry.has_changed {
                    self.entry.has_changed = true
                    self.entry.secret = ""
                    self.entry.has_changed = true
                }
                self.entry.secret = new_value
                self.entry.has_changed = true
            }
        ))
        .focused(self.$is_focused)
        .onChange(of: self.is_focused) { _, focused in
            if !focused && self.entry.secret.isEmpty {
                self.entry.has_changed = false
            }
        }
    }
}
