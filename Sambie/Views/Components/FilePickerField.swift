//
//  FilePickerField.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/3/25.
//

import SwiftUI

/// A view that allows users to pick a file or directory using a file importer.
struct FilePickerField: View {
    
    // MARK: - Properties
    let label: String
    @Binding var url: URL?
    @State private var path: String = ""
    var defaultPath: URL? = nil
    
    // Constants for layout:
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Label:
            Text(self.label)
                .font(.caption)
                .foregroundColor(Config.UI.Colors.secondary)
            
            HStack(spacing: 0) {
                
                // Textfield:
                TextField(
                    "",
                    text: self.$path,
                    onCommit: { self.url = URL(fileURLWithPath: self.path) }
                )
                .onChange(of: self.path) { _, newPath in
                    self.url = URL(fileURLWithPath: newPath)
                }
                .textFieldStyle(.plain)
                .padding(self.padding)
                .background(Config.UI.Colors.fieldsBackground)

                // Button:
                Button(action: self.fileChooser) {
                    Text("Choose")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, self.padding + self.horizontalPadding)
                        .padding(.vertical, self.padding)
                        .background(Config.UI.Colors.primary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
        }
        .onAppear { self.path = self.url?.path ?? "" }
        .onChange(of: self.url) { _, newURL in
            if let newURL = newURL, newURL.path != self.path {
                self.path = newURL.path
            }
        }
    }
    
    private func fileChooser() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if let defaultPath = self.defaultPath {
            panel.directoryURL = defaultPath
        }
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.url = selectedURL
            self.path = selectedURL.path
        }
    }
}
