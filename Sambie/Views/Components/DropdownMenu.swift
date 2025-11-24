//
//  DropdownMenu.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/23/25.
//

import SwiftUI

struct DropdownMenu<Content: View>: View {
    
    // MARK: - Properties
    let icon: String = "chevron.down.square.fill"
    var selectedItem: String
    var list: () -> Content

    
    // MARK: - Initializer
    init(
        selectedItem: String,
        @ViewBuilder list: @escaping () -> Content
    ) {
        self.selectedItem = selectedItem
        self.list = list
    }
    

    // MARK: - Views
    var body: some View {
        Menu {
            self.list()
        } label: {
            HStack {
                Text(self.selectedItem)
                Image(systemName: self.icon)
                    .foregroundColor(Config.UI.Colors.text)
            }
            .modifier(RoundedDropdownMenuStyle())
        }
        .buttonStyle(.plain)
    }
}
