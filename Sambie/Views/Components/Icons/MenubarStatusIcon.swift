//
//  MenubarStatusIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI

struct MenuBarStatusIcon: View {
    // MARK: - Properties
    let mountID: PersistentIdentifier
    @Environment(MountStateManager.self) private var stateManager
    
    
    // MARK: - View
    var body: some View {
        let state = stateManager.getState(for: mountID)
        
        if !state.errors.isEmpty {
            MenuErrorIcon()
        } else {
            switch state.status {
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
