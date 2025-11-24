//
//  SambaURLField.swift
//  Sambie
//
//  A URL input field with parse button for Samba shares.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import SwiftUI

struct SambaURLParserField: View {
    
    // MARK: - Properties
    @Binding var urlString: String
    @Binding var validationErrors: [Error]
    let mount: Mount
    
    private let parseIcon = Image(systemName: "arrow.down.circle")
    
    // Constants for layout:
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    
    
    // MARK: - View
    var body: some View {
        HStack(spacing: 0) {
            TextField("", text: self.$urlString)
                .textFieldStyle(.plain)
                .padding(self.padding)
                .background(Config.UI.Colors.fieldsBackground)
            
            Button(action: {
                self.parseURL()
            }) {
                HStack(spacing: 4) {
                    self.parseIcon
                    Text("Parse")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, self.padding + self.horizontalPadding)
                .padding(.vertical, self.padding)
                .background(Config.UI.Colors.primary)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(Rectangle())
            .disabled(urlString.isEmpty)
        }
        .cornerRadius(self.cornerRadius)
    }
    
    
    // MARK: - Methods
    /// Parses the URL and updates the mount's fields.
    private func parseURL() {
        do {
            let (user, host, share) = try MountShare.parseURL(self.urlString)
            mount.user = user ?? ""
            mount.host = host
            mount.share = share
            
            // Clear URL-specific errors:
            validationErrors.removeAll { error in
                if let configError = error as? ConfigurationError,
                   case .invalidURL = configError {
                    return true
                }
                return false
            }
        } catch {
            if !validationErrors.contains(where: {
                ($0 as? ConfigurationError) != nil
            }) {
                validationErrors.append(error)
            }
        }
    }
}
