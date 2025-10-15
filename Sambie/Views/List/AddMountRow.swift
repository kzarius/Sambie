//
//  Add.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 3/17/25.
//

import SwiftUI

struct AddMountRow: View {
    
    // MARK: - Properties
    private var newMount: Mount?
    
    
    // MARK: - View
    var body: some View {
        // On click, change our state variables to change the mount details view:
        Button(action: {
            self.newMount = Mount()
        }) {
            HStack {
                Image(systemName: Config.UI.Icons.List.add)
                    .foregroundStyle(Config.UI.Colors.utility)
                
                Text("Add Mount")
            }
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .listRowSeparator(.hidden)
    }
}
