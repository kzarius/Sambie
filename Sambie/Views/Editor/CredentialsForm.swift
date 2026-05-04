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
    let hasExistingPassword: Bool

    @FocusState private var isEditingPassword: Bool
    
    
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
                        ZStack(alignment: .leading) {
                            SecureField("", text: self.$password)
                                .focused(self.$isEditingPassword)

                            // Show bullet overlay when a password is saved and user hasn't tapped in yet:
                            if self.hasExistingPassword && !self.isEditingPassword && self.password.isEmpty {
                                Text(String(repeating: "●", count: 8))
                                    .foregroundStyle(.primary)
                                    .font(.system(size: 8))
                                    .onTapGesture {
                                        self.isEditingPassword = true
                                    }
                            }
                        }
                    }
                    
                    LabeledInputField(label: "Host") {
                        HostField(
                            hostname: $formData.pendingHostname,
                            share: $formData.wrappedValue.share,
                            username: $formData.wrappedValue.user,
                            password: self.password
                        )
                    }
                    
                    LabeledInputField(label: "Share") {
                        SharePickerField(
                            share: $formData.share,
                            hostname: $formData.pendingHostname,
                            username: $formData.wrappedValue.user,
                            password: self.password
                        )
                    }
                }
            }
        }
    }
}
