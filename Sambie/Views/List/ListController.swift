//
//  ListController.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 26/3/2026.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
/// Manages state and display logic for the mount list.
final class ListController {

    // MARK: - Properties
    private let accessor: MountAccessor
    private(set) var allMountIDs: [PersistentIdentifier: [PersistentIdentifier]] = [:]
    private(set) var orderedHostIDs: [PersistentIdentifier] = []


    // MARK: - Initializer
    init(accessor: MountAccessor) {
        self.accessor = accessor
        Task { await self.fetchMounts() }
    }


    // MARK: - Methods
    func fetchMounts() async {
        self.allMountIDs = await self.accessor.getMountIDs()
        self.orderedHostIDs = await self.accessor.getAllHostIDs()
    }
    
    func getHostData(for hostID: PersistentIdentifier) async -> HostDataObject? {
        await self.accessor.getHostData(for: hostID)
    }

    /// Reorders host groups and persists the new order.
    func moveGroup(from source: IndexSet, to destination: Int) async {
        var reordered = self.orderedHostIDs
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, hostID) in reordered.enumerated() {
            try? await self.accessor.setHostOrder(for: hostID, order: index)
        }
        await self.fetchMounts()
    }
}
