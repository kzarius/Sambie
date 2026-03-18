//
//  Host+resolve.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 18/3/2026.
//

import Foundation
import SwiftData

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
}
