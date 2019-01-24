// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import ReplicantSwift

final class TunnelConfiguration
{
    var name: String?
    var replicantConfiguration: ReplicantConfig?
    var clientConfig: ClientConfig

    static let keyLength = 32

    init(name: String?, clientConfig: ClientConfig, replicantConfig: ReplicantConfig? = nil)
    {
        self.name = name
        self.replicantConfiguration = replicantConfig
        self.clientConfig = clientConfig
    }
}

extension TunnelConfiguration: Equatable
{
    static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool
    {
        return lhs.name == rhs.name &&
            lhs.replicantConfiguration == rhs.replicantConfiguration &&
            lhs.clientConfig == rhs.clientConfig
    }
}




