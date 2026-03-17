//
//  OpenInFinderButton.swift
//  Sambie
//
//  Button to open mount in Finder.
//
//  Created by Kaeo McKeague-Clark on [DATE]
//

import SwiftUI
import AppKit

struct OpenInFinderButton: View {

    // MARK: - Properties
    let mountPoint: URL?

    // MARK: - Body
    var body: some View {
        Button(action: self.openInFinder) {
            Image(systemName: Config.UI.Icons.List.openMount)
                .foregroundStyle(Config.UI.Colors.utility)
        }
        .buttonStyle(PlainButtonStyle())
    }

    
    // MARK: - Methods
    private func openInFinder() {
        guard let mountPoint = mountPoint else { return }
        NSWorkspace.shared.open(mountPoint)
    }
}
