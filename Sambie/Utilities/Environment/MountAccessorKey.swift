//
//  MountAccessorKey.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 12/4/25.
//

import SwiftUI

/// This file defines a custom key for SwiftUI's environment system.
/// It allows you to place an instance of MountAccessor into the environment of a view hierarchy. Any child view can then easily access that MountAccessor instance using the @Environment(\.mountAccessor) property wrapper. This is a form of dependency injection, making the MountAccessor available throughout your app's UI without needing to pass it manually through view initializers.
private struct MountAccessorKey: EnvironmentKey {
    static let defaultValue: MountAccessor? = nil
}

extension EnvironmentValues {
    var mountAccessor: MountAccessor? {
        get { self[MountAccessorKey.self] }
        set { self[MountAccessorKey.self] = newValue }
    }
}
