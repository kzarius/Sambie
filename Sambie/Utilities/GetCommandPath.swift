//
//  GetCommandPath.swift
//  Shell Mounts
//
//  Created by Kaeo McKeague-Clark on 5/12/25.
//

import Foundation

/// Resolves the path of a command using the `which` command.
/// Returns the path of the command if a valid path is sent.
/// - Parameters:
/// - command: The command to resolve.
/// - Returns: A URL object with the path of the command.
/// - Throws: An error if the command is not found.
func getCommandPath(_ command: String) throws -> URL {
    // Set up the process:
    let process = Process()
    process.executableURL = Config.Command.Paths.which
    process.arguments = [command]
    
    // Set up the output pipe:
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw CommandError.invalid_command
        }
    } catch {
        throw CommandError.invalid_command
    }
    
    let data = try pipe.fileHandleForReading.readToEnd()
    let path = String(data: data!, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return URL(fileURLWithPath: path).standardized
}
