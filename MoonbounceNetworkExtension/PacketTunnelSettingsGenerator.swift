// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import Network
import NetworkExtension

class PacketTunnelSettingsGenerator
{
    let tunnelConfiguration: TunnelConfiguration

    init(tunnelConfiguration: TunnelConfiguration)
    {
        self.tunnelConfiguration = tunnelConfiguration
    }

    func generateNetworkSettings() -> NEPacketTunnelNetworkSettings
    {
        /* iOS requires a tunnel endpoint, whereas in WireGuard it's valid for
         * a tunnel to have no endpoint, or for there to be many endpoints, in
         * which case, displaying a single one in settings doesn't really
         * make sense. So, we fill it in with this placeholder, which is not
         * a valid IP address that will actually route over the Internet.
         */
        let remoteAddress = "\(tunnelConfiguration.clientConfig.host)"

        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: remoteAddress)

        // These are the Google DNS Settings, we will use these for now
        let dnsServerStrings = ["8.8.8.8", "8.8.4.4.", "2001:4860:4860::8888", "2001:4860:4860::8844"]
        let dnsSettings = NEDNSSettings(servers: dnsServerStrings)
        dnsSettings.matchDomains = [""] // All DNS queries must first go through the tunnel's DNS
        networkSettings.dnsSettings = dnsSettings

        // Based on Replicant AES Overhead size
        let aesOverheadSize: NSNumber = 81
        networkSettings.tunnelOverheadBytes = aesOverheadSize
        
        if let replicantConfig = tunnelConfiguration.replicantConfiguration
        {
            networkSettings.mtu = NSNumber(value: replicantConfig.chunkSize)
        }

        let (ipv4Routes, ipv6Routes) = routes()
        let (ipv4IncludedRoutes, ipv6IncludedRoutes) = includedRoutes()

        let ipv4Settings = NEIPv4Settings(addresses: ipv4Routes.map { $0.destinationAddress }, subnetMasks: ipv4Routes.map { $0.destinationSubnetMask })
        ipv4Settings.includedRoutes = ipv4IncludedRoutes
        networkSettings.ipv4Settings = ipv4Settings

        let ipv6Settings = NEIPv6Settings(addresses: ipv6Routes.map { $0.destinationAddress }, networkPrefixLengths: ipv6Routes.map { $0.destinationNetworkPrefixLength })
        ipv6Settings.includedRoutes = ipv6IncludedRoutes
        networkSettings.ipv6Settings = ipv6Settings

        return networkSettings
    }

    private func ipv4SubnetMaskString(of addressRange: IPAddressRange) -> String {
        let length: UInt8 = addressRange.networkPrefixLength
        assert(length <= 32)
        var octets: [UInt8] = [0, 0, 0, 0]
        let subnetMask: UInt32 = length > 0 ? ~UInt32(0) << (32 - length) : UInt32(0)
        octets[0] = UInt8(truncatingIfNeeded: subnetMask >> 24)
        octets[1] = UInt8(truncatingIfNeeded: subnetMask >> 16)
        octets[2] = UInt8(truncatingIfNeeded: subnetMask >> 8)
        octets[3] = UInt8(truncatingIfNeeded: subnetMask)
        return octets.map { String($0) }.joined(separator: ".")
    }

    private func routes() -> ([NEIPv4Route], [NEIPv6Route])
    {
        var ipv4Routes = [NEIPv4Route]()
        var ipv6Routes = [NEIPv6Route]()
        
        let host = tunnelConfiguration.clientConfig.host
        
        switch host
        {
        case .ipv4(let address):
            ipv4Routes.append(NEIPv4Route(destinationAddress: "\(address)", subnetMask: "255.255.255.255"))
        case .ipv6(let address):
            /* Big fat ugly hack for broken iOS networking stack: the smallest prefix that will have
             * any effect on iOS is a /120, so we clamp everything above to /120. This is potentially
             * very bad, if various network parameters were actually relying on that subnet being
             * intentionally small. TODO: talk about this with upstream iOS devs.
             */
            ipv6Routes.append(NEIPv6Route(destinationAddress: "\(address)", networkPrefixLength: 128))
        case .name(let name, _):
            print("\nUnable to resolve included routes: host was a domain name which is currently unsupported - \(name)\n")
        }

        return (ipv4Routes, ipv6Routes)
    }

    private func includedRoutes() -> ([NEIPv4Route], [NEIPv6Route])
    {
        var ipv4IncludedRoutes = [NEIPv4Route]()
        var ipv6IncludedRoutes = [NEIPv6Route]()

        let host = tunnelConfiguration.clientConfig.host

        switch host
        {
        case .ipv4(let address):
            ipv4IncludedRoutes.append(NEIPv4Route(destinationAddress: "\(address)", subnetMask: "255.255.255.255"))
        case .ipv6(let address):
            ipv6IncludedRoutes.append(NEIPv6Route(destinationAddress: "\(address)", networkPrefixLength: 128))
            
        case .name(let name, _):
            print("\nUnable to resolve included routes: host was a domain name which is currently unsupported - \(name)\n")
        }
        
        return (ipv4IncludedRoutes, ipv6IncludedRoutes)
    }
}

private extension Data {
    func hexEncodedString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}
