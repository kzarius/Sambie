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
@Observable
final class EditorActions {
    
    // MARK: - Properties
    // Published:
    var formData: MountDataObject?
    var password: String = ""
    var validationErrors: [Error] = []
    var sambaURL: String = ""
    
    // Private:
    private let accessor: MountAccessor
    private let stateManager: MountStateManager
    private let monitor: MountMonitor
    private let modelContext: ModelContext
    private var mount: Mount?
    private let onDismiss: () -> Void
    
    // Computed:
    var isNewMount: Bool {
        guard let mount = self.mount else { return false }
        return mount.isNew(in: self.modelContext)
    }
    var isConnected: Bool {
        guard let mount = self.mount else { return false }
        return self.stateManager.getState(for: mount.persistentModelID).status == .connected
    }
    
    
    // MARK: - Initializer
    private init(
        accessor: MountAccessor,
        stateManager: MountStateManager,
        monitor: MountMonitor,
        modelContext: ModelContext,
        onDismiss: @escaping () -> Void
    ) {
        self.accessor = accessor
        self.stateManager = stateManager
        self.monitor = monitor
        self.modelContext = modelContext
        self.onDismiss = onDismiss
    }
    
    // MARK: - Static Methods
    static func forNewMount(
        accessor: MountAccessor,
        stateManager: MountStateManager,
        monitor: MountMonitor,
        modelContext: ModelContext,
        onDismiss: @escaping () -> Void
    ) async -> EditorActions {
        let actions = EditorActions(
            accessor: accessor,
            stateManager: stateManager,
            monitor: monitor,
            modelContext: modelContext,
            onDismiss: onDismiss
        )
        
        // Fetch max order from saved mounts:
        let maxOrder = (try? modelContext.fetch(FetchDescriptor<Mount>()).filter { !$0.isTemporary }.map(\.order).max()) ?? -1
        
        let newMount = Mount(order: maxOrder + 1)
        newMount.isTemporary = true
        modelContext.insert(newMount)
        actions.mount = newMount
        actions.formData = await newMount.toDataObject()
        actions.sambaURL = SambaURL.create(from: actions.formData!).absoluteString
        
        return actions
    }
    
    static func forExistingMount(
        mountID: PersistentIdentifier,
        accessor: MountAccessor,
        stateManager: MountStateManager,
        monitor: MountMonitor,
        modelContext: ModelContext,
        onDismiss: @escaping () -> Void
    ) async -> EditorActions? {
        guard let existingMount = modelContext.model(for: mountID) as? Mount else {
            return nil
        }
        
        let actions = EditorActions(
            accessor: accessor,
            stateManager: stateManager,
            monitor: monitor,
            modelContext: modelContext,
            onDismiss: onDismiss
        )
        
        actions.mount = existingMount
        actions.formData = await existingMount.toDataObject()
        actions.sambaURL = SambaURL.create(from: actions.formData!).absoluteString
        
        return actions
    }
    
    
    // MARK: - Public Methods
    func addMount() throws {
        guard let mount = self.mount else { return }
        
        self.updateMountFromFormData()
        try self.validateMount()
        try self.savePasswordToKeychain(password: self.password)
        mount.isTemporary = false
        try self.modelContext.save()
        self.onDismiss()
    }
    
    func saveMount() throws {
        self.updateMountFromFormData()
        try self.validateMount()
        try self.savePasswordToKeychain(password: self.password)
        try self.modelContext.save()
        self.onDismiss()
    }
    
    func saveWithRemount() async throws {
        guard let mount = self.mount else { return }
        
        self.updateMountFromFormData()
        try self.validateMount()
        try self.modelContext.save()
        
        let client = await MountClient(
            mountID: mount.persistentModelID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.unmount()
        await client.mount()
        
        self.onDismiss()
    }
    
    func deleteMount() throws {
        guard let mount = self.mount else { return }
        
        // Clean up any existing mount state before deleting:
        Task {
            await self.monitor.cleanupMount(id: mount.persistentModelID)
        }
        
        try self.deletePasswordFromKeychain()
        self.modelContext.delete(mount)
        try self.modelContext.save()
        self.onDismiss()
    }
    
    func deleteWithUnmount() async throws {
        guard let mount = self.mount else { return }
        
        let client = await MountClient(
            mountID: mount.persistentModelID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
        await client.unmount()
        await self.monitor.cleanupMount(id: mount.persistentModelID)
        try self.deleteMount()
    }
    
    func cancelEditing() {
        guard let mount = self.mount else { return }
        
        if mount.isNew(in: self.modelContext) {
            self.modelContext.delete(mount)
        }
        self.onDismiss()
    }
    
    func updateSambaURL() {
        guard let formData = self.formData else { return }
        self.sambaURL = SambaURL.create(from: formData).absoluteString
    }
    
    
    // MARK: - Private Methods
    private func updateMountFromFormData() {
        guard let mount = self.mount, let formData = self.formData else { return }
        
        mount.name = formData.name
        mount.user = formData.user
        mount.share = formData.share
        mount.host = Host.findOrCreate(
            hostname: formData.pendingHostname,
            port: formData.host?.port ?? Config.Ports.samba,
            in: self.modelContext
        )
    }
    
    private func validateMount() throws {
        guard let formData = self.formData else { return }
        
        try SambaMount.validateUsername(formData.user)
        try SambaMount.validateHost(formData.pendingHostname)
        try SambaMount.validateShareName(formData.share)
    }
    
    private func savePasswordToKeychain(password: String) throws {
        guard let formData = self.formData else { return }
        
        let serverURL = "smb://\(formData.pendingHostname)"
        let keychain = Keychain(
            server: serverURL,
            protocolType: .smb
        )
        
        try keychain.set(password, key: formData.user)
        logger("Saved password to system Keychain for \(formData.user)@\(formData.pendingHostname)", level: .debug)
    }
    
    private func deletePasswordFromKeychain() throws {
        guard let formData = self.formData else { return }
        
        let serverURL = "smb://\(formData.pendingHostname)"
        let keychain = Keychain(
            server: serverURL,
            protocolType: .smb
        )
        
        try keychain.remove(formData.user)
        logger("Removed password from system Keychain for \(formData.user)@\(formData.pendingHostname)", level: .debug)
    }
}
