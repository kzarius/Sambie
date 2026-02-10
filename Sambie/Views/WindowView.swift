//
//  ContentView.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 10/10/25.
//

import SwiftUI
import SwiftData

struct WindowView: View {
    
    // MARK: - Properties
    @State private var editorState: EditorState = .closed
    
    
    // MARK: - View
    var body: some View {
        ListView(editorState: self.$editorState)
        .frame(minWidth: 200)
        // Open the editor sheet when it's state is not closed:
        .sheet(isPresented: Binding(
            get: { self.editorState != .closed },
            set: { if !$0 { self.editorState = .closed } }
        )) {
            EditorView(state: self.$editorState)
        }
    }
}
