//
//  Menubar.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/13/25.
//

import SwiftUI
import SwiftData

struct MenuBar: View {
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Mount.name, order: .forward) private var mounts: [Mount]
    
    var body: some View {
        Group {
            // Mount list:
            if mounts.isEmpty {
                Text("No mounts found.")
            } else {
                ForEach(mounts, id: \.name) { mount in
                    MenuBarRow(mount: mount)
                }
            }
            
            Divider()
            
            // Mount main window:
            Button(
                action: { self.openWindow(id: "mounts-window") },
                label: { Text("Show Mounts") }
            )
            
            // Quit:
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
