//
//  EditorView.swift
//  Sambie
//
//  An editor view for creating and modifying mount configurations. This view is triggered when a user selects a mount from the list or opts to create a new one.
//
//  Created by Kaeo McKeague-Clark on 3/17/25.
//

import SwiftData
import SwiftUI

struct EditorView: View {
    
    // MARK: - Properties
    @Environment(\.mountAccessor) private var accessor
    @Environment(MountStateManager.self) private var stateManager
    @Environment(\.mountMonitor) private var monitor
    @Environment(\.modelContext) private var modelContext
    
    @Binding var state: EditorState
    @State private var actions: EditorActions?
    
    
    // MARK: - View
    var body: some View {
        if let actions = self.actions {
            VStack(alignment: .leading, spacing: 0) {
                EditorForm(actions: actions)
            }
            .toolbar {
                EditorToolbar(actions: actions)
            }
        } else {
            ProgressView()
                .onAppear { self.loadActions() }
        }
    }
    
    
    // MARK: - Private Methods
    private func loadActions() {
        guard let accessor = self.accessor, let monitor = self.monitor else { return }
        
        Task {
            // Editor states:
            switch self.state {
                
            // Creating a new mount:
            case .creating:
                self.actions = await EditorActions.forNewMount(
                    accessor: accessor,
                    stateManager: self.stateManager,
                    monitor: monitor,
                    modelContext: self.modelContext,
                    onDismiss: { self.state = .closed }
                )
                
            // Editing a mount:
            case .editing(let id):
                self.actions = await EditorActions.forExistingMount(
                    mountID: id,
                    accessor: accessor,
                    stateManager: self.stateManager,
                    monitor: monitor,
                    modelContext: self.modelContext,
                    onDismiss: { self.state = .closed }
                )
                
            // Closing our editor:
            case .closed:
                break
            }
        }
    }
}
