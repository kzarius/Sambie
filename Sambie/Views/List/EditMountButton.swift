//
//  EditMountButton.swift
//  Sambie
//
//  Button to open mount editor.
//
//  Created by Kaeo McKeague-Clark on [DATE]
//

import SwiftUI

struct EditMountButton: View {

    // MARK: - Properties
    let mount: Mount
    let onTap: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            Image(systemName: Config.UI.Icons.List.edit)
                .foregroundStyle(Config.UI.Colors.utility)
                .padding(.trailing, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
