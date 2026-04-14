//
//  ListController.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 25/3/2026.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
/// Manages state and actions for a single mount list row.
final class ListRowController {

    // MARK: - Properties
    let mount: Mount
    private let stateManager: MountStateManager
    private let accessor: MountAccessor

    private(set) var mountPoint: URL? = nil
    private(set) var mountConnection: MountClient?

    var transientState: MountStateManager.MountState {
        self.stateManager.getState(for: self.mount.persistentModelID)
    }

    var backgroundColour: Color {
        switch self.transientState.status {
        case .disconnecting: return Config.UI.Colors.List.connecting
        case .disconnected:  return Config.UI.Colors.List.disconnected
        case .connecting:    return Config.UI.Colors.List.connecting
        case .connected:     return Config.UI.Colors.List.connected
        }
    }


    // MARK: - Initializer
    /// Initializes the controller with the necessary dependencies.
    init(mount: Mount, stateManager: MountStateManager, accessor: MountAccessor) {
        self.mount = mount
        self.stateManager = stateManager
        self.accessor = accessor
    }


    // MARK: - Methods
    /// Sets up the MountClient for this mount and starts observing its state.
    func initialize() async {
        self.mountConnection = await MountClient(
            mountID: self.mount.persistentModelID,
            accessor: self.accessor,
            stateManager: self.stateManager
        )
    }

    /// Handles the toggle action for mounting/unmounting button based on the current status.
    func handleMountToggle() async {
        switch self.transientState.status {
        case .connected:
            self.mount.autoReconnect = false
            await self.mountConnection?.unmount()
        case .disconnected:
            await self.mountConnection?.mount()
        case .connecting:
            await self.mountConnection?.cancel()
        default:
            break
        }
    }

    /// Fetches the mount point URL for the connected mount.
    func fetchMountPoint() async {
        guard self.transientState.status == .connected else {
            self.mountPoint = nil
            return
        }
        if let path = try? await SambaMount.getMountPath(
            user: self.mount.user,
            host: self.mount.host?.hostname ?? "",
            share: self.mount.share
        ) {
            self.mountPoint = URL(filePath: path)
        } else {
            self.mountPoint = nil
        }
    }

    /// Dismisses any error state for this mount, if present.
    func dismissError() async {
        await self.mountConnection?.dismissError()
    }

    /// Returns the editor state for editing this mount.
    func editMount() -> EditorState {
        .editing(self.mount.persistentModelID)
    }
}
