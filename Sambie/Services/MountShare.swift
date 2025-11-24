//
//  MountShare.swift
//  Sambie
//
//  Utility to mount SMB shares using NetFS.
//
//  Created by Kaeo McKeague-Clark on 10/21/25.
//

import Foundation

/// Utility struct to handle mounting SMB shares using NetFS.
struct MountShare {
    
    let mountBasePath = Config.Paths.sambaMountBase
    
    let host: String
    let share: String
    let username: String
    let password: String?
    let customMountPoint: URL?
    
    init(
        host: String,
        share: String,
        username: String,
        password: String?,
        customMountPoint: URL? = nil
    ) {
        self.host = host
        self.share = share
        self.username = username
        self.password = password
        self.customMountPoint = customMountPoint
    }
}
