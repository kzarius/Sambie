//
//  HostField.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 17/3/2026.
//

import SwiftUI

/// A labeled host field with a trailing connection-test button.
/// Opens a `ConnectionTestView` popover to verify the host is reachable.
struct HostField: View {

    // MARK: - Properties
    @Binding var hostname: String
    let share: String
    let username: String
    let password: String


    // MARK: - View
    var body: some View {
        PopoverPickerField(
            text: self.$hostname,
            icon: "antenna.radiowaves.left.and.right",
            help: "Test connection to host"
        ) {
            ConnectionTestView(
                host: self.hostname,
                share: self.share,
                username: self.username
            )
        }
    }
}
