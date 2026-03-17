//
//  PopoverPickerField.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 17/3/2026.
//

import SwiftUI

/// A text field with a trailing icon button that opens a popover containing a custom content view.
/// Use this as a base for any field that needs an inline action popover — e.g. browsing shares or testing a host.
struct PopoverPickerField<Content: View>: View {

    // MARK: - Properties

    // The bound text value displayed in the field:
    @Binding var text: String
    // The SF Symbol name for the trailing button icon.
    let icon: String
    // The tooltip shown on hover over the trailing button:
    let help: String
    // The edge the popover arrow should appear on:
    var arrowEdge: Edge = .bottom
    // The content view rendered inside the popover:
    @ViewBuilder let content: () -> Content

    @State private var showPopover: Bool = false


    // MARK: - Views
    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: self.$text)
            self.popoverButton
        }
    }

    /// The trailing button that toggles the popover.
    private var popoverButton: some View {
        Button {
            self.showPopover.toggle()
        } label: {
            Image(systemName: self.icon)
        }
        .buttonStyle(.plain)
        .help(self.help)
        .popover(isPresented: self.$showPopover, arrowEdge: self.arrowEdge) {
            self.content()
        }
    }
}
