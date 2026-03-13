//
//  EditorErrorPopup.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/26/25.
//

import SwiftUI

struct EditorErrorPopup: View {
    
    // MARK: Properties
    @Binding var validationErrors: [Error]
    let backgroundColor = Config.UI.Colors.error
    

    // MARK: Body
    var body: some View {
        Popup(
            content: self.makeContent,
            onDismiss: self.onDismiss,
            background: self.backgroundColor
        )
    }
    
    var makeContent: some View {
        VStack(alignment: .leading) {
            // Only show header if multiple errors:
            if self.validationErrors.count > 1 {
                Text("The following errors were found:")
                    .font(.caption)
            }
            
            ForEach(Array(self.validationErrors.enumerated()), id:\.offset) { index, error in
                Text(error.localizedDescription)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
        }
    }
    
    /// Closing the popup will clear the validation errors.
    private func onDismiss() { self.validationErrors = [] }
}
