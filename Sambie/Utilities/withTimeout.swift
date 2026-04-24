//
//  withTimeout.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 20/4/2026.
//

import Foundation

private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var settled = false
    func settle(_ work: () -> Void) {
        lock.lock(); defer { lock.unlock() }
        guard !settled else { return }
        settled = true; work()
    }
}

/// Races an async operation against a timeout. The operation runs detached
/// so a blocking call (e.g. NetFSMountURLSync) doesn't prevent the timeout from firing.

func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
        let once = Once()
        Task.detached {
            do {
                let result = try await operation()
                await once.settle { continuation.resume(returning: result) }
            } catch {
                await once.settle { continuation.resume(throwing: error) }
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            once.settle {
                continuation.resume(throwing: ClientError.mountFailed(reason: "Timed out after \(Int(seconds))s"))
            }
        }
    }
}
