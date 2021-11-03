//
//  Keys.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 2/15/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import NetworkExtension
import ReplicantSwiftClient
import ReplicantSwift
import Network

enum Keys: String
{
    case moonbounceConfigKey = "MoonbounceConfiguration"
    case clientConfigKey = "ClientConfiguration"
    case replicantConfigKey = "ReplicantConfiguration"
    case tunnelNameKey = "Tunnel Name"
    case portKey = "Port"
    case hostKey = "Host"
    case vpnConfigKey = "VPN"
    case vpnType = "VPNType"
    case vpnSubType = "VPNSubType"
    case providerBundleIDConfigKey = "ProviderBundleIdentifier"
}
