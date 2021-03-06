// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import ReplicantSwift
import NetworkExtension

final class TunnelConfiguration: NSObject
{
    static let keyLength = 32
    
    let nameKey = "name"
    let directoryKey = "directory"
    let rConfigKey = "replicantConfiguration"
    let cConfigKey = "clientConfig"
    
    var tunnelProviderProtocol: NETunnelProviderProtocol
    var name: String?
    var directory: URL?
    var replicantConfiguration: ReplicantConfig<SilverClientConfig>?
    var clientConfig: ClientConfig
    
    init(name: String?, clientConfig: ClientConfig, replicantConfig: ReplicantConfig<SilverClientConfig>? = nil, directory: URL? = nil)
    {
        self.name = name
        self.replicantConfiguration = replicantConfig
        self.clientConfig = clientConfig
        self.directory = directory
        
        let appId = Bundle.main.bundleIdentifier!
        tunnelProviderProtocol = NETunnelProviderProtocol()
        tunnelProviderProtocol.providerBundleIdentifier = "\(appId).NetworkExtension"
        
        let vpnConfig = [Keys.providerBundleIDConfigKey.rawValue: tunnelProviderProtocol.providerBundleIdentifier,
                         Keys.vpnType.rawValue: "VPN",
                         Keys.vpnSubType.rawValue: tunnelProviderProtocol.providerBundleIdentifier]
        appLog.debug("\nappID = \(appId)")
        
        if replicantConfig != nil
        {
            tunnelProviderProtocol.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfig,
                                                            Keys.replicantConfigKey.rawValue: replicantConfig!,
                                                            Keys.vpnConfigKey.rawValue: vpnConfig]
        }
        else
        {
            tunnelProviderProtocol.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfig,
                                                            Keys.vpnConfigKey.rawValue: vpnConfig]
        }
        
        tunnelProviderProtocol.serverAddress = "\(clientConfig.host)"
    }
    
    convenience init?(name: String?, providerProtocol: NETunnelProviderProtocol)
    {
        
        let maybeclientConfig = providerProtocol.providerConfiguration?[Keys.clientConfigKey.rawValue]
        let maybeReplicantConfig = providerProtocol.providerConfiguration?[Keys.replicantConfigKey.rawValue]
        
        guard let clientConfig = maybeclientConfig as? ClientConfig
            else
        {
            return nil
        }
        
        if let replicantConfig = maybeReplicantConfig as? ReplicantConfig<SilverClientConfig>
        {
            self.init(name: name, clientConfig: clientConfig, replicantConfig: replicantConfig)
        }
        else
        {
            self.init(name: name, clientConfig: clientConfig)
        }
    }
}




