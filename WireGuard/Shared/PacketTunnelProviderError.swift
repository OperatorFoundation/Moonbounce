//
//  PacketTunnelProviderError.swift
//  Moonbounce
//
//  Created by Mafalda on 2/6/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation

enum PacketTunnelProviderError: String, Error
{
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}
