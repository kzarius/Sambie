//
//  MountShare+Mounting.swift
//  Sambie
//
//  Core mounting operations using NetFS.
//
//  Created by Kaeo McKeague-Clark on 11/14/25.
//

import Foundation
import NetFS

extension MountShare {
    
    /// Mounts the SMB share and returns the actual mount point URL.
    /// - Returns: The URL where the share was actually mounted
    func mount() throws -> URL {
        let urlString = "smb://\(host)/\(share)"
        
        guard let url = URL(string: urlString) as CFURL? else {
            throw ConfigurationError.invalidURL(
                reason: "Could not construct valid URL from string: \(urlString)"
            )
        }
        
        try doNetFSMount(url: url)
        
        if let customMount = self.customMountPoint {
            if checkForMount(path: customMount.path) {
                logger("Share mounted at custom mount point: \(customMount.path)", level: .debug)
                return customMount
            } else {
                logger("Custom mount point specified but mount not found there", level: .error)
                throw ClientError.mountFailed
            }
        }
        
        guard let actualMount = try self.searchForMountPoint() else {
            logger("Failed to find the mount in '\(mountBasePath)'", level: .error)
            throw ClientError.mountFailed
        }
        
        return actualMount
    }
    
    /// Attempts to mount the share using NetFS.
    private func doNetFSMount(url: CFURL) throws {
        logger("Mounting share at URL: \(url) to mount point: \(customMountPoint?.path ?? "auto")")
        
        var mountPoints: Unmanaged<CFArray>?
        
        let status = NetFSMountURLSync(
            url,
            customMountPoint as CFURL?,
            username as CFString,
            (password ?? "") as CFString,
            nil,
            nil,
            &mountPoints
        )
        
        try self.mountStatusHandler(status: status)
    }
    
    /// Handles NetFS status codes.
    private func mountStatusHandler(status: Int32) throws {
        switch status {
        case 0:
            logger("Mount operation completed successfully.", level: .debug)
        case 17:
            logger("Mount point already existed, but doesn't affect anything.", level: .debug)
        default:
            logger("Mount operation failed with status code: \(status)", level: .error)
            throw ClientError.mountFailed
        }
    }
}
