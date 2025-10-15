//
//  CreateEditorContext.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/14/25.
//

import SwiftData

private func configureEditorContext(
    mountID: PersistentIdentifier?,
    modelContainer: ModelContainer
) -> (context: ModelContext, mount: Mount) {
    
    // 1. Create a new context for this editing session.
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    
    let mount: Mount

    // 2. Check if we are editing an existing mount or creating a new one.
    if let _mountID = mountID,
        let mainContextMount = RetrieveMount.getMount(id: _mountID, in: modelContainer) {
        // Create a copy of the mount for editing.
        let editableMount = Mount(from: mainContextMount)
        context.insert(editableMount)
        mount = editableMount
    } else {
        // Create a new mount and insert it into our editing context.
        let newMount = Mount()
        context.insert(newMount)
        mount = newMount
    }
}
