//
//  EditorDeleteModal.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 9/11/25.
//

import SwiftUI

struct EditorConfirmModal: View {
    @Binding var isActive: Bool
    let isDelete: Bool
    let onConfirm: () -> Void
    
    private var title: String {
        self.isDelete ? "Delete Active Mount" : "Save Active Mount"
    }
    
    private var message: String {
        "This mount is currently active. \(self.isDelete ? "Deleting" : "Saving") will disconnect it first\(self.isDelete ? " and remove it permanently" : "")."
    }
    
    var body: some View {
        ConfirmationModal(is_active: self.$isActive) {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text(self.title)
                        .font(.headline)
                    Text(self.message)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 15) {
                    ToolbarButton(
                        title: "Cancel",
                        color: Config.UI.Colors.secondary
                    ) { self.isActive = false }
                    
                    ToolbarButton(title: self.isDelete ? "Delete" : "Save") {
                        self.onConfirm()
                        self.isActive = false
                    }
                }
            }
        }
    }
}
