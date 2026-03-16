//
//  MountMonitorKey.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 16/3/2026.
//

import SwiftUI

/// An environment key for accessing the `MountMonitor` instance.
/// This allows any view in the SwiftUI hierarchy to access the `MountMonitor` without needing to pass it through view initializers.
private struct MountMonitorKey: EnvironmentKey {
    static let defaultValue: MountMonitor? = nil
}

extension EnvironmentValues {
    var mountMonitor: MountMonitor? {
        get { self[MountMonitorKey.self] }
        set { self[MountMonitorKey.self] = newValue }
    }
}
