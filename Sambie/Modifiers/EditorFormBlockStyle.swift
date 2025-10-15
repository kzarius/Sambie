//
//  EditorFormSectionStyle.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 6/24/25.
//

import SwiftUI

struct EditorFormBlockStyle: ViewModifier {
    
    // MARK: - Properties
    let padding = Config.UI.Layout.padding
    
    
    // MARK: - Body
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) { content }
    }
}
