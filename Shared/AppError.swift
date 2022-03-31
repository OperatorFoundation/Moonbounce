//
//  PacketTunnelProviderError.swift
//  Moonbounce
//
//  Created by Mafalda on 2/6/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation
import MoonbounceShared

protocol AppError: Error
{
    typealias AlertText = (title: String, message: String)

    var alertText: AlertText { get }
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
