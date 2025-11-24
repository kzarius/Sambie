//
//  MountFormState.swift
//  Sambie
//
//  A wrapper class to send via environment variable and manage the currently selected mount for editing.
//
//  Created by Kaeo McKeague-Clark on 10/23/25.
//

import SwiftUI
import SwiftData

@Observable
class MountFormState {
    // MARK: - Properties
    var editing: Mount?
    var formData: Mount?
    
    
    // MARK: - Methods
    /// Starts editing a mount by creating a temporary copy
    func startEditing(_ mount: Mount) {
        self.editing = mount
        self.formData = Mount(
            id: mount.id,
            order: mount.order,
            name: mount.name,
            user: mount.user,
            host: mount.host,
            share: mount.share,
            customMountPoint: mount.customMountPoint
        )
    }
    
    /// Applies changes from the copy back to the original mount
    @MainActor
    @discardableResult
    func applyChanges() -> Bool {
        guard let original = self.editing, let copy = self.formData else {
            return false
        }

        logger("Applying these changes: \(copy.name), \(copy.user) to \(original.name), \(original.user)", level: .debug)
        original.name = copy.name
        original.user = copy.user
        original.host = copy.host
        original.share = copy.share
        original.customMountPoint = copy.customMountPoint
        
        return true
    }
    
    /// Discards changes by clearing the editing state
    func close() {
        editing = nil
        formData = nil
    }
}
