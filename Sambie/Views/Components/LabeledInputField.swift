//
//  LabeledInputField.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/17/25.
//

import SwiftUI

struct LabeledInputField<Content: View>: View {
    
    // MARK: - Properties
    let label: String
    let field: () -> Content

    
    // MARK: - Initializer
    init(
        label: String,
        @ViewBuilder field: @escaping () -> Content
    ) {
        self.label = label
        self.field = field
    }
    

    // MARK: - Views
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label for the input field:
            Text(self.label).modifier(LabelTextStyle())
            
            // The input field itself:
            self.field()
                .modifier(TextFieldStyle())
                .modifier(RoundedBorderStyle())
        }
    }
}
