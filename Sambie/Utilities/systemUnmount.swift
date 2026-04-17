//
//  systemUnmount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/12/25.
//

import Foundation
import Subprocess

/// Unmount a volume using diskutil.
/// - Parameters:
///   - path: The mount point path to unmount
///   - forcefully: Whether to force unmount
/// - Returns: A boolean indicating if the unmount was successful
func systemUnmount(
    path: String,
    forcefully: Bool = false
) async throws -> Bool {
    var arguments = ["unmount"]
    if forcefully { arguments.append("force") }
    arguments.append(path)

    let result = try await Subprocess.run(
        .name("diskutil"),
        arguments: .init(arguments),
        output: .discarded,
        error: .discarded
    )

    logger("Unmounting path: \(path), forcefully: \(forcefully), success: \(result.terminationStatus.isSuccess)", level: .debug)

    guard result.terminationStatus.isSuccess else {
        throw ClientError.unmountFailed
    }

    return true
}
