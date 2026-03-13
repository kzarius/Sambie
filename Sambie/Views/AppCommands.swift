//
//  AppCommands.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 13/3/2026.
//

import SwiftUI

/// Defines a custom set of commands for the app's menu bar.
struct AppCommands: Commands {
    var body: some Commands {
        
        // Replace the default "New Item" menu group with an empty one:
        CommandGroup(replacing: .newItem) { }
        
        // Help menu:
        CommandGroup(replacing: .help) {
            
            // Add a button to open the GitHub page:
            Button("Sambie on GitHub") {
                if let url = URL(string: "https://github.com/kzarius/sambie") {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        // Navigate menu:
        CommandMenu("Navigate") {
            
            // Mount list (m):
            Button("Mount List") {
                NSApp.windows
                    .first { $0.identifier?.rawValue == "mounts-window" }?
                    .makeKeyAndOrderFront(nil)
            }
            .keyboardShortcut("m", modifiers: .command)

            Divider()

            // Settings (,):
            Button("Settings") {
                NSApp.windows
                    .first { $0.identifier?.rawValue == "settings-window" }?
                    .makeKeyAndOrderFront(nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
