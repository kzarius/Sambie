//
//  ParsedSMBMount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 13/2/2026.
//

/// Represents a parsed SMB mount entry from the system.
/// Used in SambaMount service to identify and manage SMB mounts.
struct ParsedSMBMount {
    let sourceURL: String
    let mountPath: String
    let fullLine: Substring
}
