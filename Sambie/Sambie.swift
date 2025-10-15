//
//  SambieApp.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

@main
struct Sambie: App {
    
    /// Determine if the mounts have been loaded.
    var isInitialized: Bool = false
    
    var mountMonitor: MountMonitor?
    
    /// The model container used to share the context between views.
    var sharedModelContainer: ModelContainer = {
        
        // Clear any problematic stores if needed during development. Usually if we change the models attached:
        // try? clearPreviousStore()
        
        // Define schemas:
        let schema = Schema([
            Mount.self
        ])
        
        // Create container with unique identifier:
        let modelConfiguration = ModelConfiguration(
            schema: schema
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.mainContext.autosaveEnabled = false
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Main window:
        Window("Mounts", id: "mounts-window") {
            WindowView()
                .modelContainer(self.sharedModelContainer)
                .overlay {
                    if !self.isInitialized {
                        // Show a loading indicator while initializing:
                        ProgressView("Loading mounts...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.windowBackgroundColor).opacity(0.8))
                            .task {
                                // Monitor the mounts:
//                                self.mountMonitor = await MountMonitor(container: sharedModelContainer)
//                                await self.mount_monitor?.startMonitoring()
//                                self.isInitialized = true
                            }
                    }
                }
        }
        
        // Menu bar:
        MenuBarExtra() {
            if self.isInitialized {
                MenuBar()
                    .modelContainer(self.sharedModelContainer)
            } else {
                ProgressView("Loading...")
            }
        } label: {
            MenuBarIcon()
                .modelContainer(self.sharedModelContainer)
        }
    }
    
    /// Function to clear previous store during development.
    private static func clearPreviousStore() throws {
        let url = URL.applicationSupportDirectory.appending(path: Config.dbPath)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            logger("Removed previous model store.", level: .debug)
        }
    }
}
