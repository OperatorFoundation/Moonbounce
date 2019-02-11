// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import NetworkExtension
import Network

// Creates mock tunnels for the iOS Simulator.

//#if targetEnvironment(simulator)
class MockTunnels
{
    static let tunnelNames = [
        "demo",
        "home",
        "office"
    ]
    static let address = "192.168.%d.%d/32"
    static let port = NWEndpoint.Port(rawValue: 51820)!
    // TODO: Demo Host
    static let hostString = "8.8.8.8"
    static let dnsServers = ["8.8.8.8", "8.8.4.4"]
    static let allowedIPs = "0.0.0.0/0"

    static func createMockTunnels() -> [NETunnelProviderManager]
    {
        return tunnelNames.map
        {
            tunnelName -> NETunnelProviderManager in
            
            let host = NWEndpoint.Host(hostString)
            let clientConfig = ClientConfig(withPort: port, andHost: host)
            let tunnelConfiguration = TunnelConfiguration(name: tunnelName, clientConfig: clientConfig)
            let tunnelProviderManager = NETunnelProviderManager()
            
            tunnelProviderManager.protocolConfiguration = tunnelConfiguration.tunnelProviderProtocol
            tunnelProviderManager.localizedDescription = tunnelConfiguration.name
            tunnelProviderManager.isEnabled = true

            return tunnelProviderManager
        }
    }
}
//#endif
