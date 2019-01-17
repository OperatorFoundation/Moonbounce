// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import ReplicantSwift

final class TunnelConfiguration
{
    var name: String?
    var replicantConfiguration: ReplicantConfig?
    var interface: InterfaceConfiguration
    let peers: [PeerConfiguration]

    static let keyLength = 32

    init(name: String?, interface: InterfaceConfiguration, peers: [PeerConfiguration], replicantConfig: ReplicantConfig? = nil)
    {
        self.interface = interface
        self.peers = peers
        self.name = name
        self.replicantConfiguration = replicantConfig

        let peerPublicKeysArray = peers.map { $0.publicKey }
        let peerPublicKeysSet = Set<Data>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            fatalError("Two or more peers cannot have the same public key")
        }
    }
}

extension TunnelConfiguration: Equatable
{
    static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool
    {
        return lhs.name == rhs.name &&
            lhs.interface == rhs.interface &&
            Set(lhs.peers) == Set(rhs.peers)
    }
}
