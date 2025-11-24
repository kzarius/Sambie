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
    @State private var mountFormState = MountFormState()
    
    // MARK: - View
    var body: some View {
        
        ListView()
            .frame(minWidth: 200)
            // Editor Sheet:
            // When mountFormState.editing is not nil, present the EditorView sheet.
            .sheet(isPresented: Binding(
                get: { self.mountFormState.editing != nil },
                set: {
                    if !$0 { self.mountFormState.editing = nil }
                }
            )) {
                EditorView()
                    .environment(self.mountFormState)
            }
            .environment(self.mountFormState)
    }
}
