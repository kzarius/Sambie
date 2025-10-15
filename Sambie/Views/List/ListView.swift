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
    @Query(sort: \Mount.name, order: .forward) var mounts: [Mount]
    
    
    // MARK: - View
    var body: some View {
        List {
            // Show the list of mounts:
            ForEach(self.mounts) { mount in
                ListRow(mount: mount)
            }
            
            // Row to "Add a new mount":
            AddMountRow()
        }
        .navigationTitle("Mounts")
    }
}
