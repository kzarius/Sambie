//
//  EditorState.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 4/2/2026.
//

import SwiftData

enum EditorState: Equatable {
    case closed
    case creating
    case editing(PersistentIdentifier)
}
