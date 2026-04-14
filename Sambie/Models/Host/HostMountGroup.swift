//
//  HostMountGroup.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 2/4/2026.
//

/// A value type representing a host group and its associated mounts as data objects.
struct HostMountGroup: Sendable {
    let host: HostDataObject?
    let mounts: [MountDataObject]
}
