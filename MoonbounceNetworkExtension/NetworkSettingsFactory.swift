//
//  NetworkSettingsFactory.swift
//  MoonbounceNetworkExtension
//
//  Created by Mafalda on 5/5/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import NetworkExtension
import ReplicantSwift
import SwiftQueue

let googleDNSipv4 = "8.8.8.8"
let googleDNS2ipv4 = "8.8.4.4"
let googleDNSipv6 = "2001:4860:4860::8888"
let googleDNS2ipv6 = "2001:4860:4860::8844"
let tunIPSubnetMask = "255.255.255.255"
let tunIPv4Address = "10.0.0.1"
let tunIPv6Address = ""
let tunIPv6RouteAddress = ""

/// host must be an ipv4 address and port "ipAddress:port". For example: "127.0.0.1:1234".
func makeNetworkSettings(host: String) -> NEPacketTunnelNetworkSettings
{
    let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: host)
    
    // These are the Google DNS Settings, we will use these for now
    let dnsServerStrings = [googleDNSipv4, googleDNS2ipv4, googleDNSipv6, googleDNS2ipv6]
    let dnsSettings = NEDNSSettings(servers: dnsServerStrings)
    // dnsSettings.matchDomains = [""] // All DNS queries must first go through the tunnel's DNS
    networkSettings.dnsSettings = dnsSettings
    
    let ipv4Settings = NEIPv4Settings(addresses: [tunIPv4Address], subnetMasks: [tunIPSubnetMask])
    // No routes specified, use the default route.
    ipv4Settings.includedRoutes = [NEIPv4Route.default()]
    networkSettings.ipv4Settings = ipv4Settings
    
    let ipv6Settings = NEIPv6Settings(addresses: [tunIPv6Address], networkPrefixLengths: [64])
    ipv6Settings.includedRoutes = [NEIPv6Route.default()]
    networkSettings.ipv6Settings = ipv6Settings
    
    
        // FIXME: These should be set later when we have a ReplicantConnection
    //    // This should be derived from the specific polish specified by the replicant config
    //    networkSettings.tunnelOverheadBytes = 0
    //
    //    if let polish = replicantConfig.polish as? SilverClientConfig
    //    {
    //        networkSettings.mtu = NSNumber(value: polish.chunkSize)
    //    }

    return networkSettings
}
