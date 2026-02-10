//
//  AddMountRow.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 3/17/25.
//

import SwiftUI
import SwiftData

struct AddMountRow: View {
    
    // MARK: - Properties
    @Binding var editorState: EditorState
    
    
    // MARK: - View
    var body: some View {
        // On click, change our state variables to change the mount details view:
        Button(action: self.addMount) {
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
    
    
    // MARK: - Methods
    /// Switches the editor state to creating a new mount.
    private func addMount() { self.editorState = .creating }
}
