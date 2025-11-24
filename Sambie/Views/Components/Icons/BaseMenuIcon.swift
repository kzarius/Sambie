//
//  BaseMenuIcon.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 7/10/25.
//

import SwiftUI

struct BaseMenuIcon: View {
    
    // MARK: - Properties
    // Passed:
    let name: String
    let color: Color?
    let colors: (Color, Color)?
    
    
    // MARK: - Initializer
    init(
        name: String,
        color: Color? = nil,
        colors: (Color, Color)? = nil
    ) {
        self.name = name
        self.color = color
        self.colors = colors
        
        // Only one of color or colors should be provided:
        if (color == nil && colors == nil) || (color != nil && colors != nil) {
            fatalError("BaseMenuIcon must have either a color or a colors tuple provided, but not both.")
        }
    }
    
    
    // MARK: - View
    var body: some View {
        Image(systemName: self.name)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                colors != nil
                    ? colors!.0 : color!,
                colors != nil
                    ? colors!.1 : Color.white
            )
    }
}
