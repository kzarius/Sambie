//
//  ZombieIndicator.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 25/2/2026.
//

import SwiftUI

struct ZombieIndicator: View {
    let since: Date
    let timeout = Config.Connection.mountTimeout

    private var elapsed: Int { Int(Date().timeIntervalSince(self.since)) }
    private var total: Int { Int(self.timeout) }

    var body: some View {
        Image(systemName: "allergens")
            .foregroundStyle(.green)
            .help("Server unreachable — zombie unmount in \(max(0, self.total - self.elapsed))s")
            .transition(.scale.combined(with: .opacity))
    }
}
