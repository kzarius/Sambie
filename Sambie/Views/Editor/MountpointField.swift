//
//  MountpointField.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/31/25.
//

import SwiftUI

struct MountpointField: View {
    // MARK: - Properties
    @Binding var url: URL?
    @State private var path: String = ""
    
    // View Layout Constants:
    private let cornerRadius: CGFloat = Config.UI.Layout.borderCornerRadius
    private let padding: CGFloat = Config.UI.Layout.padding
    private let horizontalPadding: CGFloat = Config.UI.Layout.horizontalPadding
    private let fieldsBackground = Config.UI.Colors.fieldsBackground
    
    // Add explicit initializer
    init(url: Binding<URL?>) {
        self._url = url
    }
    

    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Label:
            Text("Mount Point")
                .font(.caption)
                .foregroundColor(Config.UI.Colors.secondary)
            
            HStack(spacing: 0) {
                            
                // TextField:
                TextField(
                    "",
                    text: $path,
                    prompt: Text("Default Path"),
                )
                .onSubmit {
                    url = URL(fileURLWithPath: path)
                }
                .onChange(of: path) { _, newPath in
                    url = URL(fileURLWithPath: newPath)
                }
                .textFieldStyle(.plain)
                .padding(padding)
                .background(fieldsBackground)
                
                // Button:
                Button(action: selectPath) {
                    Image(systemName: "folder")
                        .foregroundStyle(.white)
                        .padding(.horizontal, padding + horizontalPadding)
                        .padding(.vertical, padding)
                        .background(Config.UI.Colors.primary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .onAppear { path = url?.path ?? "" }
        .onChange(of: url) { _, newURL in
            if let newURL = newURL, newURL.path != path {
                path = newURL.path
            }
        }
    }
    
    private func selectPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            url = selectedURL
            path = selectedURL.path
        }
    }
}
