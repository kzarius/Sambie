//
//  MenubarStatusIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI

struct MenuBarStatusIcon: View {
    // MARK: - Properties
    let status: ConnectionStatus
    let errors: [String]
    
    
    // MARK: - View
    var body: some View {
        if !self.errors.isEmpty {
            MenuErrorIcon()
        } else {
            switch self.status {
            case .connecting:
                MenuConnectingIcon()
            case .connected:
                MenuConnectedIcon()
            case .disconnecting:
                MenuConnectingIcon()
            case .disconnected:
                MenuNotConnectedIcon()
            }
        }
    }
}
