//
//  diskutilUnmount.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/12/25.
//

import Foundation

/// Use diskutil to unmount a stubborn sshfs mount.
/// - Returns: A boolean indicating if the unmount was successful.
func diskutilUnmount(path: String, forcefully: Bool? = nil) async throws -> Bool {
    // diskutil unmount (force) target
    let diskutil = await Command.run(
        Config.Command.Paths.diskutil,
        with: ["unmount", (forcefully == true ? "force" : ""), path]
    // grep -c Unmount successful
    )
        
    let results = await Command.run(
        Config.Command.Paths.grep,
        with: ["-c", "Unmount successful"],
        input: diskutil.output
    )
    
    if results.status != .success {
        throw MountError.command_failed(command: "diskutil unmount")
    }
    
    return results.output.contains("1")
}
