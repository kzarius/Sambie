//
//  diskutilUnmount.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 5/12/25.
//

import Foundation
import Darwin

/// Unmount a volume using Darwin's unmount system call.
/// - Parameters:
///   - path: The mount point path to unmount
///   - forcefully: Whether to force unmount (MNT_FORCE flag)
/// - Returns: A boolean indicating if the unmount was successful
func systemUnmount(
    path: String,
    forcefully: Bool = false
) throws -> Bool {
    let flags: Int32 = forcefully ? MNT_FORCE : 0
    
    let result = Darwin.unmount(path, flags)
    
    logger("Unmounting path: \(path) with flags: \(flags), result: \(result)", level: .debug)
    
    guard result == 0 else {
        let errorCode = errno
        
        switch errorCode {
        case EBUSY:
            throw ClientError.unmountFailed
        case EINVAL:
            throw ClientError.notFound
        case EPERM, EACCES:
            throw ClientError.permissionDenied
        case ENOENT:
            throw ClientError.notFound
        default:
            throw ClientError.unknown(code: errorCode, output: String(cString: strerror(errorCode)))
        }
    }
    
    return true
}
