//
//  EditorValidationPopup.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/27/25.
//

import SwiftUI

struct EditorValidationPopup: View {
    
    // MARK: Properties
    let errors: [MountError]
    let onDismiss: () -> Void
    
    
    // MARK: Initializer
    init(
        errors: [MountError],
        onDismiss: @escaping () -> Void
    ) {
        self.errors = errors
        self.onDismiss = onDismiss
    }

    
    // MARK: Body
    var body: some View {
        Popup(
            content: self.formatErrors(),
            onDismiss: onDismiss,
            background: Config.UI.Colors.error
        )
    }
    
    private func formatErrors() -> some View {
        Group {
            Text("The following errors were found:")
            ForEach(self.errors, id: \.self) { error in
                Text(error.localizedDescription)
            }
        }
    }
}
