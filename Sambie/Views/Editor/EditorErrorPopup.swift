//
//  EditorErrorPopup.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/26/25.
//

import SwiftUI

struct EditorErrorPopup: View {
    
    // MARK: Properties
    @Binding var validation_errors: [Error]
    let background_color = Config.UI.Colors.error
    

    // MARK: Body
    var body: some View {
        Popup(
            content: self.makeContent,
            onDismiss: self.onDismiss,
            background: self.background_color
        )
    }
    
    var makeContent: some View {
        VStack(alignment: .leading) {
            Text("The following errors were found:")
                .font(.caption)
            
            ForEach(Array(self.validation_errors.enumerated()), id:\.offset) { index, error in
                Text(error.localizedDescription)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                
            }
        }
    }
    
    /// Closing the popup will clear the validation errors.
    private func onDismiss() { self.validation_errors = [] }
}
