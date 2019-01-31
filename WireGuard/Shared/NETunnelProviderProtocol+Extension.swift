// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import NetworkExtension
import Replicant
import ReplicantSwift

enum PacketTunnelProviderError: String, Error
{
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}

extension NETunnelProviderProtocol
{

    enum Keys: String
    {
        case clientConfigKey = "ClientConfiguration"
        case replicantConfigKey = "ReplicantConfiguration"
    }

    convenience init?(tunnelConfiguration: TunnelConfiguration)
    {
        self.init()

        let appId = Bundle.main.bundleIdentifier!
        providerBundleIdentifier = "\(appId).network-extension"
        
        if let replicantConfig = tunnelConfiguration.replicantConfiguration
        {
            providerConfiguration = [Keys.clientConfigKey.rawValue: tunnelConfiguration.clientConfig, Keys.replicantConfigKey.rawValue: replicantConfig]
        }
        else
        {
            providerConfiguration = [Keys.clientConfigKey.rawValue: tunnelConfiguration.clientConfig]
        }
        
        serverAddress = "\(tunnelConfiguration.clientConfig.host)"
    }

    func asTunnelConfiguration(called name: String? = nil) -> TunnelConfiguration?
    {
        let maybeclientConfig = providerConfiguration?[Keys.clientConfigKey.rawValue]
        let maybeReplicantConfig = providerConfiguration?[Keys.replicantConfigKey.rawValue]
        
        guard let clientConfig = maybeclientConfig as? ClientConfig
        else
        {
            return nil
        }
        
        if let replicantConfig = maybeReplicantConfig as? ReplicantConfig
        {
            return TunnelConfiguration(name: name, clientConfig: clientConfig, replicantConfig: replicantConfig)
        }
        else
        {
            return TunnelConfiguration(name: name, clientConfig: clientConfig)
        }
    }

}
