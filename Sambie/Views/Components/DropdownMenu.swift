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
    var selected_item: String
    var list: () -> Content

    
    // MARK: - Initializer
    init(
        selected_item: String,
        @ViewBuilder list: @escaping () -> Content
    ) {
        self.selected_item = selected_item
        self.list = list
    }
    

    // MARK: - Views
    var body: some View {
        Menu {
            list()
        } label: {
            HStack {
                Text(selected_item)
                Image(systemName: self.icon)
                    .foregroundColor(Config.UI.Colors.text)
            }
            .modifier(RoundedDropdownMenuStyle())
        }
        .buttonStyle(.plain)
    }
}
