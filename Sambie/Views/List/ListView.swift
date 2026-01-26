//
//  ListView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftData
import SwiftUI

struct ListView: View {
    
    // MARK: - Properties
    @Binding var editingMountID: PersistentIdentifier?
    @Query(sort: \Mount.order) private var mounts: [Mount]

    
    // MARK: - View
    var body: some View {
        List {
            // Show the list of mounts:
            ForEach(self.mounts) { mount in
                ListRow(
                    mount: mount,
                    editingMountID: self.$editingMountID
                )
            }
            
            // Row to "Add a new mount":
            AddMountRow(editingMountID: $editingMountID)
        }
        .onAppear {
            logger("ListView appeared with \(self.mounts.count) mounts.")
        }
        .navigationTitle("Mounts")
    }
}
