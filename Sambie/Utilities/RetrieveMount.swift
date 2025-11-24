//
//  RetrieveMount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/13/25.
//

import SwiftData

struct RetrieveMount {
    
    // MARK: - Static Methods
    /// Retrieves a Mount object by its PersistentIdentifier and model container.
    static func getMount(
        id mountID: PersistentIdentifier,
        in modelContainer: ModelContainer
    ) -> Mount? {
        guard let mount = modelContainer.mainContext.model(for: mountID) as? Mount else {
            logger("Mount invalidated or not found.", level: .debug)
            return nil
        }
        return mount
    }
    /// Retrieves a Mount object by its PersistentIdentifier and model context.
    static func getMount(
        id mountID: PersistentIdentifier,
        in context: ModelContext
    ) -> Mount? {
        guard let mount = context.model(for: mountID) as? Mount else {
            logger("Mount invalidated or not found.", level: .debug)
            return nil
        }
        return mount
    }
    
    /// Retrieves all Mount objects from the model container.
    static func getAllMounts(in modelContainer: ModelContainer) -> [Mount] {
        return getAllMounts(in: modelContainer.mainContext)
    }
    /// Retrieves all Mount objects from the model context.
    static func getAllMounts(in context: ModelContext) -> [Mount] {
        let fetchDescriptor = FetchDescriptor<Mount>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            logger("Failed to fetch mounts: \(error)", level: .error)
            return []
        }
    }
}
