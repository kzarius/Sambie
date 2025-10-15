//
//  MenubarStatusIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI

struct MenuBarStatusIcon: View {
    // MARK: - Properties
    let state: MountState
    
    
    // MARK: - View
    var body: some View {
        if self.state.error != nil {
            MenuErrorIcon()
        } else {
            switch self.state.status {
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
