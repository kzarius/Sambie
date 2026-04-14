//
//  ConnectionTestView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 6/30/25.
//

import SwiftUI
import SwiftData

/// A view that runs a connection test against a given host and displays the result.
/// Tests DNS resolution and SMB port accessibility in sequence.
/// Designed to be shown as a popover — opening the popover triggers the test automatically.
struct ConnectionTestView: View {

    // MARK: - Properties
    // The hostname or IP address to test connectivity against:
    let host: String
    // The SMB share name to validate (checked for invalid characters only):
    let share: String
    // The username to validate (checked for invalid characters only):
    let username: String
    
    // Accessor to interface with the data models:
    @Environment(\.mountAccessor) private var accessor
    
    // The human-readable result string. Empty string means success; nil means not yet run:
    @State private var result: String? = nil
    // Whether the test is currently running. Used to show the loading indicator:
    @State private var isLoading: Bool = false
    // Incremented to re-trigger the `.task` on refresh:
    @State private var runID: UUID = UUID()


    // MARK: - Views
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header showing the target host and a refresh button:
            self.headerView
            Divider()
            // Result: loading, success, or error:
            self.contentView
        }
        .frame(minWidth: 220, minHeight: 100)
        // Run the test as soon as the popover opens, and again on refresh:
        .task(id: self.runID) { await self.runTest() }
    }
    
    
    // MARK: - Private Methods
    /// The top bar showing the target host and a re-test button.
    private var headerView: some View {
        HStack(spacing: 6) {
            
            // Icon indicating this is a network connection test:
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.secondary)
            Text(self.host.isEmpty ? "No host specified" : self.host)
                .font(.headline)
                .lineLimit(1)
            
            Spacer()
            
            // Show a spinner while testing, or a refresh button when idle:
            if self.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                self.retestButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// A button that re-runs the connection test.
    private var retestButton: some View {
        Button {
            self.runID = UUID()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.plain)
        .help("Re-test connection")
    }

    /// The main content area — shows a loading state, success, or error.
    @ViewBuilder
    private var contentView: some View {
        if self.isLoading {
            self.loadingView
        } else if let result = self.result {
            if result.isEmpty {
                self.successView
            } else {
                self.errorView(message: result)
            }
        }
    }

    /// Shown while the connection test is in progress.
    private var loadingView: some View {
        HStack(spacing: 8) {
            ArrowLoadingIcon()
            Text("Testing connection...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Shown when the connection test passes all checks.
    private var successView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Connection successful.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Config.UI.Colors.success)
            Text("The host was reached successfully at port \(Config.Ports.samba).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    /// Shown when the connection test fails, displaying the error message.
    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Connection failed.", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(Config.UI.Colors.error)
            Text(message)
                .font(.caption)
                .foregroundStyle(Config.UI.Colors.error)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    /// Validates credentials and tests DNS resolution and SMB port accessibility.
    /// Sets `result` to an empty string on success, or an error message on failure.
    private func runTest() async {
        guard !self.host.isEmpty else {
            self.result = "Enter a host to test."
            return
        }

        self.isLoading = true
        self.result = nil

        do {
            // Validate inputs before making any network calls:
            try SambaMount.validateUsername(self.username)
            try SambaMount.validateHost(self.host)
            try SambaMount.validateShareName(self.share)

            // Verify DNS resolution:
            try await Host.checkPortAccessible(host: self.host, port: Config.Ports.samba)

            // Empty string signals success:
            self.result = ""
        } catch {
            self.result = error.localizedDescription
        }

        self.isLoading = false
    }
}
