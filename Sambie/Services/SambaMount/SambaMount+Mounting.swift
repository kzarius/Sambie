//
//  SambaMount+Mounting.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 24/2/2026.
//

import Foundation
import NetFS

extension SambaMount {
    
    /// Mount the share via NetFS.
    /// - Parameter mountData: The mount data object containing connection details.
    static func mountShare(mountData: MountDataObject) async throws {
        let urlString = try await self.buildURL(from: mountData)
        let password = await self.retrievePassword(for: mountData)
        let timeout = await Config.Connection.connectTimeout
        
        // Perform the mount with a timeout to prevent hanging:
        let mountPath = try await withTimeout(seconds: timeout) {
            try await self.performMount(
                urlString: urlString,
                username: mountData.user,
                password: password
            )
        }
        
        await logger("NetFS mounted at: \(mountPath)", level: .info)
    }


    // MARK: - Private Helpers

    /// Constructs an SMB URL string from the provided mount data.
    /// - Parameter mountData: The mount data object to build the URL from.
    /// - Returns: A string representation of the SMB URL.
    /// - Throws: `ClientError.mountFailed` if the URL cannot be constructed.
    @MainActor
    private static func buildURL(from mountData: MountDataObject) throws -> String {
        let url = SambaURL.create(from: mountData)
        guard !url.absoluteString.isEmpty else {
            throw ClientError.mountFailed(reason: "Failed to construct SMB URL.")
        }
        return url.absoluteString
    }

    /// Performs the NetFS mount operation asynchronously.
    /// - Parameters:
    ///   - urlString: The SMB URL string to mount.
    ///   - username: The username to authenticate with.
    ///   - password: The password to authenticate with, or nil for guest access.
    /// - Returns: The local mount path if successful.
    /// - Throws: `ClientError.mountFailed` if the mount operation fails.
    private static func performMount(
        urlString: String,
        username: String,
        password: String?
    ) async throws -> String {
        let (status, mountPaths) = await withCheckedContinuation { (continuation: CheckedContinuation<(Int32, [String]?), Never>) in
            Task.detached {
                guard let serverURL = CFURLCreateWithString(kCFAllocatorDefault, urlString as CFString, nil) else {
                    continuation.resume(returning: (-1, nil))
                    return
                }

                var localMountPoints: Unmanaged<CFArray>?
                let osStatus = NetFSMountURLSync(
                    serverURL,
                    nil,
                    username as CFString?,
                    password as CFString?,
                    nil,
                    nil,
                    &localMountPoints
                )

                let extractedPaths = Self.extractMountPaths(from: localMountPoints)
                continuation.resume(returning: (osStatus, extractedPaths))
            }
        }

        guard status == 0, let path = mountPaths?.first else {
            throw ClientError.mountFailed(reason: "NetFS mount failed with status: \(status)")
        }

        return path
    }
    
    /// Extract mount paths from the unmanaged CFArray returned by NetFS.
    /// - Parameter unmanaged: The unmanaged CFArray containing mount paths.
    /// - Returns: An array of mount path strings, or nil if extraction fails.
    private static func extractMountPaths(from unmanaged: Unmanaged<CFArray>?) -> [String]? {
        guard let unmanaged = unmanaged else { return nil }
        
        let cfArray = unmanaged.takeRetainedValue()
        let nsArray = cfArray as NSArray
        
        // Convert NSArray elements to String paths, handling possible types.
        let paths: [String] = nsArray.compactMap { element in
            // If the element is already a String, return it directly.
            if let stringPath = element as? String { return stringPath }
            
            // If the element is a URL, extract its path.
            if let url = element as? URL { return url.path }
            
            // If the element is an NSURL, cast to URL and extract its path.
            if let nsurl = element as? NSURL { return (nsurl as URL).path }
            
            // If the element is none of the above, ignore it.
            return nil
        }
        
        return paths.isEmpty ? nil : paths
    }
}
