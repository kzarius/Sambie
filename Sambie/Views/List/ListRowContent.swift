//
//  ListRowContent.swift
//  Sambie
//
//  Main content button for mount list rows.
//
//  Created by Kaeo McKeague-Clark on [DATE]
//

import SwiftUI

struct ListRowContent: View {

    // MARK: - Properties
    let mount: Mount
    let onTap: () async -> Void

    // MARK: - Body
    var body: some View {
        Button {
            Task {
                await self.onTap()
            }
        } label: {
            HStack {
                ListStatusIcon(mount: mount)

                Text(mount.name)
                    .foregroundStyle(Config.UI.Colors.text)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(PlainButtonStyle())
    }
}
