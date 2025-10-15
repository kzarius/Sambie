//
//  ListErrorPopup.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/26/25.
//

import SwiftUI

struct ListErrorPopup: View {
    
    // MARK: Properties
    let message: String
    let onDismiss: () -> Void
    
    
    // MARK: Initializer
    init(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.onDismiss = onDismiss
    }

    
    // MARK: Body
    var body: some View {
        Popup(
            content: Text(message),
            onDismiss: onDismiss,
            background: Config.UI.Colors.error
        )
    }
}
