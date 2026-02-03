//
//  CredentialsForm.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/23/25.
//

import SwiftUI

/// Form fields for editing specific mount credentials.
struct CredentialsForm: View {
    
    // MARK: - Properties
    @Binding var formData: MountDataObject?
    @Binding var password: String
    
    
    // MARK: - View
    var body: some View {
        if let $formData = Binding(self.$formData) {
            
            VStack(alignment: .leading, spacing: 10) {
                
                // Fields for the selected authentication method:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                    
                    LabeledInputField(label: "Username") {
                        TextField("", text: $formData.user)
                    }
                    
                    LabeledInputField(label: "Password") {
                        SecureField("", text: self.$password)
                            .modifier(LargeTextFieldStyle())
                    }
                    
                    LabeledInputField(label: "Host") {
                        TextField("", text: $formData.host)
                    }
                    
                    LabeledInputField(label: "Share") {
                        TextField("", text: $formData.share)
                    }
                }
            }
        }
    }
}
