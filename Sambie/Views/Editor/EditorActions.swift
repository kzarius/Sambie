//
//  EditorActions.swift
//  Sambie
//
//  Handles editor business logic for adding, saving, and deleting mounts.
//
//  Created by Kaeo McKeague-Clark on 6/6/25.
//

import SwiftData
import Foundation

@MainActor
class EditorActions {
    
    // MARK: - Properties
    private let modelContext: ModelContext
    private let mountFormState: MountFormState
    
    
    // MARK: - Initializer
    init(
        modelContext: ModelContext,
        mountFormState: MountFormState
    ) {
        self.modelContext = modelContext
        self.mountFormState = mountFormState
    }
    
    
    // MARK: - Form management
    /// Validates and adds a new mount.
    func addMount() throws {
        guard let draft = self.mountFormState.formData else { throw ClientError.invalidMount }
        try self.validateMount(draft)
        guard self.mountFormState.applyChanges(), let mount = self.mountFormState.editing else { throw ClientError.invalidMount }
        self.modelContext.insert(mount)
        try self.saveAndClose()
    }
    
    /// Validates and saves an existing mount.
    func saveMount() throws {
        guard let draft = self.mountFormState.formData else { throw ClientError.invalidMount }
        try self.validateMount(draft)
        guard self.mountFormState.applyChanges() else { throw ClientError.invalidMount }
        try self.saveAndClose()
    }
    
    /// Deletes a mount.
    func deleteMount() throws {
        guard let mount = self.mountFormState.editing else { throw ClientError.invalidMount }
        self.modelContext.delete(mount)
        try self.saveAndClose()
    }
    
    /// Cancels editing and rolls back changes.
    func cancelEditing() {
        if let mount = self.mountFormState.editing,
           mount.exists(context: self.modelContext) {
            self.modelContext.rollback()
        }
        self.mountFormState.close()
    }
    
    
    // MARK: - Mount Operations
    /// Saves and remounts a connected mount.
    func saveWithRemount() async throws {
        guard let draft = self.mountFormState.formData else { throw ClientError.invalidMount }
        try self.validateMount(draft)
        guard self.mountFormState.applyChanges(), let mount = self.mountFormState.editing else { throw ClientError.invalidMount }
        try self.persist()
        let client = await MountClient(mountID: mount.persistentModelID, modelContainer: self.modelContext.container)
        await client.unmount()
        await client.mount()
        try self.saveAndClose()
    }
    
    /// Deletes and unmounts a connected mount.
    func deleteWithUnmount() async throws {
        guard let mount = self.mountFormState.editing else { throw ClientError.invalidMount }
        let client = await MountClient(mountID: mount.persistentModelID, modelContainer: self.modelContext.container)
        await client.unmount()
        self.modelContext.delete(mount)
        try self.saveAndClose()
    }
    
    func validateMount(_ mount: Mount) throws {
        try MountShare.validateFields(
            user: mount.user,
            host: mount.host,
            share: mount.share
        )
    }
    
    private func persist() throws { try self.modelContext.save() }
    
    private func saveAndClose() throws {
        try self.persist()
        self.mountFormState.close()
    }
}
