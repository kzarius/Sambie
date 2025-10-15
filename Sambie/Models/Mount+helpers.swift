//
//  Mount+helpers.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/14/25.
//

import SwiftData
import SwiftUI

extension Mount {
    
    /// exists() caller for the current mount instance.
    func exists(context: ModelContext) -> Bool {
        return Mount.exists(persistentID: self.persistentModelID, context: context)
    }
    
    /// Checks if a mount with the given persistent identifier exists in the database.
    static func exists(
        persistentID: PersistentIdentifier,
        context: ModelContext
    ) -> Bool {
        let internalID = persistentID
        
        do {
            // Try to fetch a model with this persistent ID from the database:
            let descriptor = FetchDescriptor<Mount>(
                predicate: #Predicate { $0.persistentModelID == internalID }
            )
            
            // If we return at least one, the mount exists:
            return try context.fetchCount(descriptor) > 0
        } catch {
            logger("Error checking if mount exists: \(error)", level: .error)
            // If we can't determine, assume it exists to be safe:
            return true
        }
    }
}
