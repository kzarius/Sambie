//
//  EditorModalState.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 9/12/25.
//

enum EditorModalState {
    case hidden
    case confirmSave(() async -> Void)
    case confirmDelete(() async -> Void)
    
    var is_visible: Bool {
        switch self {
        case .hidden: return false
        default: return true
        }
    }
    
    var is_delete: Bool {
        switch self {
        case .confirmDelete: return true
        default: return false
        }
    }
    
    var action: (() async -> Void)? {
        switch self {
        case .confirmSave(let action), .confirmDelete(let action):
            return action
        case .hidden:
            return nil
        }
    }
}
