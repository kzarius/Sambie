//
//  clearPersistentStore.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 19/3/2026.
//


import SwiftData

/// Clears all persisted data from the SwiftData store.
///
/// This function opens a temporary `ModelContainer` using the app's schema,
/// then fetches and deletes all model instances individually. Individual deletion
/// (rather than batch deletion via `context.delete(model:)`) is required to allow
/// SwiftData to properly handle relationship rules — specifically the nullify inverse
/// on `Mount.host`, which causes batch deletes to fail with a constraint violation.
///
/// Deletion order matters:
/// 1. `Mount` is deleted first to nullify its reference to `Host`.
/// 2. `Host` is deleted second, once no `Mount` holds a reference to it.
///
/// - Throws: Any error encountered while opening the container, fetching, or saving.
func clearPersistentStore() throws {
    let schema = Schema([
        Mount.self,
        Host.self
    ])

    let modelConfiguration = ModelConfiguration(schema: schema)
    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
    let context = container.mainContext

    // Delete Mounts first to nullify the inverse relationship on Mount.host,
    // preventing a constraint trigger violation during Host deletion:
    let mounts = try context.fetch(FetchDescriptor<Mount>())
    mounts.forEach { context.delete($0) }
    try context.save()

    // Now safe to delete Hosts since no Mounts reference them:
    let hosts = try context.fetch(FetchDescriptor<Host>())
    hosts.forEach { context.delete($0) }
    try context.save()
}
