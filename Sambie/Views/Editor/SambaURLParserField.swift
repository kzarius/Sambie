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
    @Binding var formData: MountDataObject?
    
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
        // Clear any previous URL parsing-related errors.
        validationErrors.removeAll { error in
            guard let configError = error as? ConfigurationError else { return false }
            switch configError {
            case .invalidURL, .missingHost, .missingShare, .invalidScheme:
                return true
            default:
                return false
            }
        }

        do {
            let (user, host, share) = try SambaURL.parse(urlString: self.urlString)
            
                // Ensure we have an editing mount to update, and update.
                self.formData?.user = user
                self.formData?.host = host
                self.formData?.share = share
            
        } catch {
            // Add the new error if it's not already in the list.
            let newErrorDescription = error.localizedDescription
            if !validationErrors.contains(where: { $0.localizedDescription == newErrorDescription }) {
                validationErrors.append(error)
            }
        }
    }
}
