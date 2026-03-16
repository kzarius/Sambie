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
    @State private var mountStateManager = MountStateManager()
    @State private var mountAccessor: MountAccessor
    
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
            return container
        } catch {
            // If the store is incompatible (e.g. after a schema change), delete it and retry.
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                return container
            } catch {
                fatalError("Could not create ModelContainer after clearing store: \(error)")
            }
        }
    }()
    
    
    // MARK: - Initializer
    init() {
        let accessor = MountAccessor(modelContainer: sharedModelContainer)
        _mountAccessor = State(initialValue: accessor)
    }

    
    // MARK: - Body
    var body: some Scene {
        
        // Main window:
        Window("Mounts", id: "mounts-window") {
            WindowView()
                .overlay { self.loadingOverlay }
                .environment(self.mountStateManager)
                .environment(\.mountAccessor, mountAccessor)
                .environment(\.mountMonitor, mountMonitor)
                .modelContainer(self.sharedModelContainer)
        }
        .windowResizability(.contentSize)
        .commands {
            AppCommands()
        }
        
        // Menu bar:
        MenuBarExtra() {
            if self.isInitialized {
                
                MenuBar()
                    .environment(self.mountStateManager)
                    .environment(\.mountAccessor, mountAccessor)
                    .modelContainer(self.sharedModelContainer)
            } else {
                ProgressView("Loading...")
            }
        } label: {
            
            MenuBarIcon()
                .environment(self.mountStateManager)
                .environment(\.mountAccessor, mountAccessor)
        }
        
        // Settings window:
        Window("Settings", id: "settings-window") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 300)
    }
    
    
    // MARK: - Helpers
    @ViewBuilder
    private var loadingOverlay: some View {
        if !self.isInitialized {
            ProgressView("Loading mounts...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor).opacity(0.8))
                .task {
                    self.mountMonitor = await MountMonitor(
                        accessor: self.mountAccessor,
                        stateManager: self.mountStateManager
                    )
                    await self.mountMonitor?.startMonitoring()
                    self.isInitialized = true
                }
        }
    }
    
    
    // MARK: - Store Management
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
