//
//  EditorActions.swift
//  Sambie
//
//  Handles editor business logic for adding, saving, and deleting mounts.
//
//  Created by Kaeo McKeague-Clark on 6/6/25.
//

import SwiftData
import SwiftUI
import KeychainAccess

@MainActor
class EditorActions {
    
    // MARK: - Properties
    private let accessor: MountAccessor
    private let stateManager: MountStateManager
    private let modelContext: ModelContext
    private let editingMount: Mount
    
    @Binding private var editingMountID: PersistentIdentifier?
    @Binding private var formData: MountDataObject
    
    
    // MARK: - Initializer
    init(
        accessor: MountAccessor,
        stateManager: MountStateManager,
        modelContext: ModelContext,
        editingMount: Mount,
        editingMountID: Binding<PersistentIdentifier?>,
        formData: Binding<MountDataObject>
    ) {
        self.accessor = accessor
        self.stateManager = stateManager
        self.modelContext = modelContext
        self.editingMount = editingMount
        self._editingMountID = editingMountID
        self._formData = formData
    }
    
    
    // MARK: - Form management
    /// Validates and adds a new mount.
    func addMount() throws {
        self.updateMountFromFormData()
        try self.validateMount()
        try self.savePasswordToKeychain()
        try self.saveAndClose()
    }
    
    /// Validates and saves an existing mount.
    func saveMount() throws {
        self.updateMountFromFormData()
        try self.validateMount()
        try self.savePasswordToKeychain()
        try self.saveAndClose()
    }
    
    /// Deletes a mount.
    func deleteMount() throws {
        try self.deletePasswordFromKeychain()
        self.modelContext.delete(self.editingMount)
        try self.saveAndClose()
    }
    
    /// Cancels editing and rolls back changes. A modelContext rollback is only necessary on new mounts because the newly created Mount model must be destroyed; existing mounts simply discard unsaved changes.
    func cancelEditing() {
        if self.editingMount.isNew(in: self.modelContext) {
            self.modelContext.delete(self.editingMount)
        }
        self.editingMountID = nil
    }
    
    
    // MARK: - Mount Operations
    /// Saves and remounts a connected mount.
    func saveWithRemount() async throws {
        self.updateMountFromFormData()
        try self.validateMount()
        try self.persist()

        let client = await MountClient(
            mountID: self.editingMount.persistentModelID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.unmount()
        await client.mount()

        self.editingMountID = nil
    }
    
    /// Deletes and unmounts a connected mount.
    func deleteWithUnmount() async throws {
        let client = await MountClient(
            mountID: self.editingMount.persistentModelID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.unmount()
        try self.deleteMount()
    }
    
    /// Updates the persistent model from the temporary form data object.
    private func updateMountFromFormData() {
        self.editingMount.name = self.formData.name
        self.editingMount.user = self.formData.user
        self.editingMount.host = self.formData.host
        self.editingMount.port = self.formData.port
        self.editingMount.share = self.formData.share
    }
    
    /// Validates the mount fields.
    func validateMount() throws {
        try SambaMount.validateUsername(self.formData.user)
        try SambaMount.validateHost(self.formData.host)
        try SambaMount.validateShareName(self.formData.share)
    }
    
    /// Persists changes to the model context.
    private func persist() throws { try self.modelContext.save() }
    
    /// Saves changes and closes the editor.
    private func saveAndClose() throws {
        try self.persist()
        self.editingMountID = nil
    }
    
    
    // MARK: - Keychain Management
    /// Helper to save password from formData.
    private func savePasswordToKeychain() throws {
        let keychain = Keychain(service: Config.Paths.keychainService)
        try keychain.set(
            self.formData.password,
            key: generateKeychainKey(for: self.formData.id)
        )
    }
    
    /// Helper to delete password from keychain once we delete the mount.
    private func deletePasswordFromKeychain() throws {
        let keychain = Keychain(service: Config.Paths.keychainService)
        try keychain.remove(generateKeychainKey(for: self.formData.id))
    }
}
