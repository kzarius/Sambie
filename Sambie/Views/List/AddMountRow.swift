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
    @Environment(\.modelContext) private var modelContext
    @Binding var editingMountID: PersistentIdentifier?
    
    
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
    /// Creates a new Mount on the main context and sets it for editing.
    private func addMount() {
        let newMount = Mount()
        self.modelContext.insert(newMount)
        self.editingMountID = newMount.persistentModelID
    }
}
