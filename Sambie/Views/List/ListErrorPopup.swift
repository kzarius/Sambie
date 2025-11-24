//
//  ListErrorPopup.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/26/25.
//

import SwiftUI

struct ListErrorPopup: View {
    
    // MARK: Properties
    let errors: [String]
    let onDismiss: () -> Void
    
    
    // MARK: Initializer
    init(
        errors: [String],
        onDismiss: @escaping () -> Void
    ) {
        self.errors = errors
        self.onDismiss = onDismiss
    }

    
    // MARK: Body
    var body: some View {
        Popup(
            content: Text(self.formatMessage()),
            onDismiss: self.onDismiss,
            background: Config.UI.Colors.error
        )
    }
    
    /// Formats the error messages for display.
    private func formatMessage() -> String {
        // Handle no errors:
        if self.errors.isEmpty { return "An unknown error occurred." }
        
        // Single error case:
        if (self.errors.count == 1) {
            return "\(self.errors[0])"
        }
        
        // Summarise if multiple errors:
        var output = "\(self.errors.count) errors occurred:\n"
        // List each error:
        for error in self.errors {
            output += "- \(error)\n"
        }
        
        // Trim trailing newline and return:
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
