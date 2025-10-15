//
//  RetrieveMount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/13/25.
//

import SwiftData

struct RetrieveMount {
    
    // MARK: - Static Methods
    /// Retrieves a Mount object by its PersistentIdentifier.
    static func getMount(id mountID: PersistentIdentifier, in modelContainer: ModelContainer) -> Mount? {
        return modelContainer.mainContext.model(for: mountID) as? Mount
    }
    
    /// Retrieves all Mount objects from the model container.
    static func getAllMounts(in modelContainer: ModelContainer) -> [Mount] {
        let fetchDescriptor = FetchDescriptor<Mount>()
        
        do {
            return try modelContainer.mainContext.fetch(fetchDescriptor)
        } catch {
            logger("Failed to fetch mounts: \(error)", level: .error)
            return []
        }
    }
}
