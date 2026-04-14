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
    @Query(sort: \Host.order) private var hosts: [Host]
    
    var body: some View {
        Group {
            // Mount list:
            if self.hosts.isEmpty {
                Text("No mounts found.")
            } else {
                ForEach(self.hosts) { host in
                    
                    // Only show hosts that have mounts:
                    if !host.mounts.isEmpty {
                        MenuBarHostSection(host: host)
                    }
                }
            }
            
            Divider()
            
            // Mount main window:
            Button(
                action: { self.openAndFocus(id: "mounts-window") },
                label: { Text("Show Mounts") }
            )
            
            // Settings window:
            Button(
                action: { self.openAndFocus(id: "settings-window") },
                label: { Text("Settings") }
            )
            
            Divider()
            
            // Quit:
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
    
    // MARK: - Methods
    /// Opens a window by ID and brings Sambie to the foreground.
    private func openAndFocus(id: String) {
        self.openWindow(id: id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.forEach { $0.orderFrontRegardless() }
        }
    }
}
