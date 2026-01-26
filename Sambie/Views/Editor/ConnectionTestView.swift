//
//  ConnectionTest.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 6/30/25.
//

import SwiftUI
import SwiftData

/// Takes the results of a connection test and formats them for display.
struct ConnectionTestView: View {
    
    // MARK: - Properties
    // Bound properties:
    var host: String
    @State private var results: String? = nil
    @State private var isLoading: Bool = true
    @State private var viewID: UUID = UUID()
    
    let trigger: Bool
    private let connectionSuccessCaption: String = "The host was reached successfully at port \(Config.Ports.samba)"
    
    private var headerText: String {
        self.isLoading ? "Testing connection..." :
            (self.results!.isEmpty ? "Connection successful." :
                "Connection failed:")
    }
    
    
    // MARK: - Views
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Icon:
                if self.isLoading { ArrowLoadingIcon() }
                else if self.results!.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Config.UI.Colors.success)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Config.UI.Colors.error)
                }
                
                // Status message:
                Text(self.headerText)
            }
            
            if let results = self.results {
                // If there is an error, show it:
                if !results.isEmpty {
                    Text(results)
                        .font(.caption)
                        .foregroundStyle(Config.UI.Colors.error)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                // Otherwise, show the success caption:
                } else {
                    Text(self.connectionSuccessCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        
                }
            }
        }
        .task(id: self.viewID) { await self.runTest() }
        .onChange(of: self.trigger) { _, newValue in
            if newValue {
                // Reset the view ID to trigger the task again:
                self.viewID = UUID()
                self.isLoading = true
                self.results = nil
            }
        }
    }
    
    /// Tests the connection to the mount using the provided snapshot.
    /// - Throws an error if the connection fails.
    private func runTest() async {
        do {
            // Test the mount's connection via ConnectMount():
            try await MountReadiness.checkMount(host: self.host)
            
            // No errors will produce this:
            self.results = ""
        } catch {
            self.results = error.localizedDescription
        }
        self.isLoading = false
    }
}
