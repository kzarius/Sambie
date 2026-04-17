//
//  Host+verification.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 18/3/2026.
//

import Foundation
import SwiftData
import Subprocess

extension Host {
    /// Finds an existing Host matching `hostname`, or inserts a new one.
    @MainActor
    static func findOrCreate(
        hostname: String,
        port: Int,
        in context: ModelContext
    ) -> Host {
        let descriptor = FetchDescriptor<Host>(
            predicate: #Predicate { $0.hostname == hostname }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.port = port
            return existing
        }
        let allDescriptor = FetchDescriptor<Host>(sortBy: [SortDescriptor(\.order, order: .reverse)])
        let maxOrder = (try? context.fetch(allDescriptor).first?.order) ?? -1
        let newHost = Host(hostname: hostname, port: port, order: maxOrder + 1)
        context.insert(newHost)
        return newHost
    }
    
    /// Checks whether this host's SMB port is currently accessible.
    /// - Parameter timeout: Connection timeout in seconds. Defaults to 5.
    /// - Returns: `true` if the port is open and reachable, `false` otherwise.
    func isReachable(timeout: TimeInterval = 5.0) async -> Bool {
        do {
            try await Self.checkPortAccessible(host: self.hostname, port: self.port, timeout: timeout)
            return true
        } catch {
            return false
        }
    }
    
    /// Verifies that a port is accessible on a given host using `nc`.
    /// - Throws: `ConfigurationError.invalidPort` if the port number is out of range.
    /// - Throws: `ConnectionError.portClosed` if the port is not accessible.
    static func checkPortAccessible(
        host: String,
        port: Int,
        timeout: TimeInterval = 5.0
    ) async throws {
        guard port > 0 && port <= 65535 else {
            throw ConfigurationError.invalidPort(port: port)
        }

        await logger("Checking port accessibility for host: \(host), port: \(port)")
        let result = try await Subprocess.run(
            .name("nc"),
            arguments: ["-z", "-G", String(Int(timeout)), host, String(port)],
            output: .discarded,
            error: .discarded
        )

        guard result.terminationStatus.isSuccess else {
            throw ConnectionError.portClosed(port: port)
        }
    }
}
