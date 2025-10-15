//
//  ConnectionTest.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/30/25.
//

import SwiftUI

/// Takes the results of a connection test and formats them for display.
struct ConnectionTestView: View {
    
    // MARK: - Properties
    // Bound properties:
    @State private var results: String? = ""
    @State private var is_loading: Bool = true
    @State private var view_id: UUID = UUID()
    
    let mount: MountData
    let trigger: Bool
    
    private var header_text: String {
        self.is_loading ? "Testing connection..." :
            (self.results!.isEmpty ? "Connection successful." :
                "Connection failed:")
    }
    
    
    // MARK: - Initializer
    init(
        mount: MountData,
        trigger: Bool = false
    ) {
        self.mount = mount
        self.trigger = trigger
    }
    
    
    // MARK: - Views
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Icon:
                if self.is_loading { ArrowLoadingIcon() }
                else if self.results!.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Config.UI.Colors.success)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Config.UI.Colors.error)
                }
                
                // Status message:
                Text(self.header_text)
            }
            
            if let results = self.results {
                // If there is an error, show it:
                if !results.isEmpty {
                    Text(results)
                        .foregroundStyle(Config.UI.Colors.error)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
            }
        }
        .task(id: self.view_id) { await self.runTest() }
        .onChange(of: self.trigger) { _, new_value in
            if new_value {
                // Reset the view ID to trigger the task again:
                self.view_id = UUID()
                self.is_loading = true
                self.results = nil
            }
        }
    }
    
    /// Tests the connection to the mount using the provided snapshot.
    /// - Throws an error if the connection fails.
    private func runTest() async {
        do {
            // Test the mount's connection via ConnectMount():
            try await MountClient(with: self.mount.makeSnapshot()).testConnection()
            // No errors will produce this:
            self.results = ""
        } catch {
            // Errors will produce this:
            self.results = error.localizedDescription
        }
        self.is_loading = false
    }
}
