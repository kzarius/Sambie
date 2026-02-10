//
//  MountTransfer.swift
//  Sambie
//
//  A lightweight transfer representation for dragging Mount objects.
//
//  This struct enables drag-and-drop operations for mounts in the UI by wrapping
//  only the mount's UUID. It conforms to `Transferable` and `Codable`, allowing
//  SwiftUI's `.draggable()` modifier to transfer mount identity between views.
//
//  The minimal design (containing only the UUID) keeps drag operations efficient
//  while avoiding issues with transferring SwiftData models directly, which are
//  tied to specific model contexts and cannot be safely transferred across threads.
//
//  Usage:
//  ```swift
//  .draggable(MountTransfer(id: mount.id))
//  ```
//
//  Created by Kaeo McKeague-Clark on 5/2/2026.
//

import Foundation
import UniformTypeIdentifiers
import CoreTransferable

/// A lightweight transfer representation for dragging Mount objects.
struct MountTransfer: Codable, Transferable {
    let id: UUID
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType(exportedAs: "com.sambie.mount"))
    }
}

extension UTType {
    @MainActor static let mount = UTType(exportedAs: "com.sambie.mount")
}
