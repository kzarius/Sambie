//
//  ParsedSambaURL.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//


/// Parsed components from a Samba URL.
/// Used with MountShare.parseURL().
struct ParsedSambaURL {
    let user: String
    let host: String
    let share: String
}
