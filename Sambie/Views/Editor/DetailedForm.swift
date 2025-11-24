//
//  DetailedForm.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/23/25.
//

import SwiftUI

/// Form fields for editing specific mount details.
struct DetailedForm: View {
    
    // MARK: - Properties
    @Environment(MountFormState.self) private var mountFormState
    
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            if let mount = self.mountFormState.formData {
                // Fields for the selected authentication method:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                    
                    LabeledInputField(label: "Username") {
                        TextField("", text: Binding(
                            get: { mount.user },
                            set: { mount.user = $0 }
                        ))
                    }
                    
                    LabeledInputField(label: "Host") {
                        TextField("", text: Binding(
                            get: { mount.host },
                            set: { mount.host = $0 }
                        ))
                    }
                    
                    LabeledInputField(label: "Share") {
                        TextField("", text: Binding(
                            get: { mount.share },
                            set: { mount.share = $0 }
                        ))
                    }
                }
                
                MountpointField(url: Binding(
                    get: { mount.customMountPoint },
                    set: { mount.customMountPoint = $0 ?? nil }
                ))
            }
        }
    }
}
