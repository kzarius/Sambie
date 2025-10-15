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
    var default_path: URL? = nil
    
    // Constants for layout:
    private let corner_radius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontal_padding: CGFloat = Config.UI.Layout.horizontalPadding
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label:
            Text(label)
                .font(.caption)
                .foregroundColor(Config.UI.Colors.secondary)
            
            HStack(spacing: 0) {
                
                // Textfield:
                TextField(
                    "",
                    text: $path,
                    onCommit: { url = URL(fileURLWithPath: path) }
                )
                .onChange(of: path) { _, newPath in
                    url = URL(fileURLWithPath: newPath)
                }
                .textFieldStyle(.plain)
                .padding(padding)
                .background(Config.UI.Colors.fieldsBackground)

                // Button:
                Button(action: fileChooser) {
                    Text("Choose")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, padding + horizontal_padding)
                        .padding(.vertical, padding)
                        .background(Config.UI.Colors.primary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .clipShape(RoundedRectangle(cornerRadius: corner_radius))
        }
        .onAppear { path = url?.path ?? "" }
        .onChange(of: url) { _, new_url in
            if let new_url = new_url, new_url.path != path {
                path = new_url.path
            }
        }
    }
    
    private func fileChooser() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if let default_path = default_path {
            panel.directoryURL = default_path
        }
        
        if panel.runModal() == .OK, let selected_url = panel.url {
            url = selected_url
            path = selected_url.path
        }
    }
}
