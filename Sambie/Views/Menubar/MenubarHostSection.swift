//
//  MenubarHostSection.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 23/3/2026.
//

import SwiftUI
import SwiftData

struct MenuBarHostSection: View {

    // MARK: - Properties
    let host: Host

    // MARK: - View
    var body: some View {
        Section(host.hostname) {
            ForEach(host.mounts.sorted(by: { $0.order < $1.order })) { mount in
                MenuBarMountRow(mount: mount)
            }
        }
    }
}
