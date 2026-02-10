//
//  ListRowContent.swift
//  Sambie
//
//  Main content button for mount list rows.
//
//  Created by Kaeo McKeague-Clark on [DATE]
//

import SwiftData
import SwiftUI

struct ListRowContent: View {

    // MARK: - Properties
    let mount: Mount

    
    // MARK: - Body
    var body: some View {
        HStack {
            ListStatusIcon(mountID: self.mount.persistentModelID)
            Text(self.mount.name)
                .foregroundStyle(Config.UI.Colors.text)
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
