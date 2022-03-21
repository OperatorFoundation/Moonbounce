//
//  PacketTunnelProviderError.swift
//  Moonbounce
//
//  Created by Mafalda on 2/6/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation
import MoonbounceShared

enum PacketTunnelProviderError: String, Error
{
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}

extension PacketTunnelProviderError: AppError
{
    var alertText: AlertText
    {
        switch self
        {
            case .savedProtocolConfigurationIsInvalid:
                return (alertTunnelActivationFailureTitle, alertTunnelActivationSavedConfigFailureMessage)
            case .dnsResolutionFailure:
                return (alertTunnelDNSFailureTitle, alertTunnelDNSFailureMessage)
            case .couldNotStartBackend:
                return (alertTunnelActivationFailureTitle, alertTunnelActivationBackendFailureMessage)
            case .couldNotDetermineFileDescriptor:
                return (alertTunnelActivationFailureTitle, alertTunnelActivationFileDescriptorFailureMessage)
            case .couldNotSetNetworkSettings:
                return (alertTunnelActivationFailureTitle, alertTunnelActivationSetNetworkSettingsMessage)
        }
    }
}
