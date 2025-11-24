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
    @State private var isInitialized: Bool = false
    
    @State private var mountMonitor: MountMonitor?
    
    /// The model container used to share the context between views.
    var sharedModelContainer: ModelContainer = {
        
        // Clear any problematic stores if needed during development. Usually if we change the models attached:
//         try? clearPreviousStore()
        
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
//            container.mainContext.autosaveEnabled = false
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
                                self.mountMonitor = await MountMonitor(modelContainer: sharedModelContainer)
                                await self.mountMonitor?.startMonitoring()
                                self.isInitialized = true
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
        let schema = Schema([Mount.self])
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext
            
            try context.delete(model: Mount.self)
            try context.save()
        } catch {
            print("Failed to clear mounts: \(error)")
            throw error
        }
    }
}
