//
//  ShareBrowserView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 17/3/2026.
//

import SwiftUI

/// A view that fetches and displays the available SMB shares on a given host.
/// The user can select a share from the list, which triggers the `onSelect` callback to populate the share field in the credentials form.
struct ShareBrowserView: View {

    // MARK: - Properties
    let hostname: String
    let username: String
    let password: String
    // The selected share name is passed as the argument:
    let onSelect: (String) -> Void

    @State private var shares: [String] = []
    @State private var isLoading: Bool = false
    @State private var error: String? = nil


    // MARK: - Views
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            self.headerView
            
            Divider()
            
            self.contentView
        }
        .frame(minWidth: 220, minHeight: 160)
        // Fetch shares as soon as the view appears:
        .task { await self.loadShares() }
    }

    /// The top bar of the browser, showing the target host and a refresh/loading indicator.
    private var headerView: some View {
        HStack(spacing: 6) {
            
            Image(systemName: "server.rack")
                .foregroundStyle(.secondary)
            
            // Display the host, or a placeholder if it hasn't been set yet:
            Text(self.hostname.isEmpty ? "No host specified" : self.hostname)
                .font(.headline)
                .lineLimit(1)
            
            Spacer()
            
            // Show a spinner while loading, or a refresh button when idle:
            if self.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                self.refreshButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// A button that triggers a fresh fetch of shares from the host.
    private var refreshButton: some View {
        Button {
            Task { await self.loadShares() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.plain)
        .help("Refresh shares")
    }

    /// The main content area — switches between error, empty, and list states.
    @ViewBuilder
    private var contentView: some View {
        if let error = self.error {
            self.errorView(message: error)
        } else if self.shares.isEmpty && !self.isLoading {
            self.emptyView
        } else {
            self.shareList
        }
    }

    /// Displayed when the share fetch fails or no host has been entered.
    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Displayed after a successful fetch that returned no disk shares.
    private var emptyView: some View {
        Text("No shares found.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }

    /// A scrollable list of available shares. Each row is tappable and fires the `onSelect` callback.
    private var shareList: some View {
        List(self.shares, id: \.self) { share in
            Button {
                self.onSelect(share)
            } label: {
                Label(share, systemImage: "externaldrive.connected.to.line.below")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }


    // MARK: - Private Methods

    /// Fetches the available shares from the host via `SambaMount.listShares`.
    /// Resets state before each fetch and updates `shares` or `error` on completion.
    private func loadShares() async {
        // Guard against fetching when no host has been entered:
        guard !self.hostname.isEmpty else {
            self.error = "Enter a host to browse shares."
            return
        }

        self.isLoading = true
        self.error = nil
        self.shares = []

        do {
            // Pass nil for empty strings so smbutil uses guest/anonymous access:
            self.shares = try await SambaMount.listShares(
                at: self.hostname,
                username: self.username.isEmpty ? nil : self.username,
                password: self.password.isEmpty ? nil : self.password
            )
        } catch {
            // Surface the error to the UI rather than silently failing:
            self.error = error.localizedDescription
        }

        self.isLoading = false
    }
}
