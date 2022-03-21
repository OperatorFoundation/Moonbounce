// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import NetworkExtension
import MoonbounceLibrary
import MoonbounceShared
import MoonbounceNetworkExtensionLibrary

enum TunnelsManagerError: AppError
{
    case tunnelNameEmpty
    case tunnelAlreadyExistsWithThatName
    case systemErrorOnListingTunnels(systemError: Error)
    case errorOnListingTunnels
    case systemErrorOnAddTunnel(systemError: Error)
    case systemErrorOnModifyTunnel(systemError: Error)
    case systemErrorOnRemoveTunnel(systemError: Error)

    var alertText: AlertText
    {
        switch self
        {
            case .tunnelNameEmpty:
                return (alertTunnelNameEmptyTitle, alertTunnelNameEmptyMessage)
            case .tunnelAlreadyExistsWithThatName:
                return (alertTunnelAlreadyExistsWithThatNameTitle, alertTunnelAlreadyExistsWithThatNameMessage)
            case .errorOnListingTunnels:
                return (alertSystemErrorOnListingTunnelsTitle, alertErrorOnListingTunnelsMessage)
            case .systemErrorOnListingTunnels(let systemError):
                return (alertSystemErrorOnListingTunnelsTitle, systemError.localizedUIString)
            case .systemErrorOnAddTunnel(let systemError):
                return (alertSystemErrorOnAddTunnelTitle, systemError.localizedUIString)
            case .systemErrorOnModifyTunnel(let systemError):
                return (alertSystemErrorOnModifyTunnelTitle, systemError.localizedUIString)
            case .systemErrorOnRemoveTunnel(let systemError):
                return (alertSystemErrorOnRemoveTunnelTitle, systemError.localizedUIString)
        }
    }
}

enum TunnelsManagerActivationAttemptError: AppError {
    case tunnelIsNotInactive
    case failedWhileStarting(systemError: Error) // startTunnel() throwed
    case failedWhileSaving(systemError: Error) // save config after re-enabling throwed
    case failedWhileLoading(systemError: Error) // reloading config throwed
    case failedBecauseOfTooManyErrors(lastSystemError: Error) // recursion limit reached

    var alertText: AlertText
    {
        switch self
        {
            case .tunnelIsNotInactive:
                return (alertTunnelActivationErrorTunnelIsNotInactiveTitle, alertTunnelActivationErrorTunnelIsNotInactiveMessage)
            case .failedWhileStarting(let systemError),
                 .failedWhileSaving(let systemError),
                 .failedWhileLoading(let systemError),
                 .failedBecauseOfTooManyErrors(let systemError):
                return (alertTunnelActivationSystemErrorTitle, "\(alertTunnelActivationSystemErrorMessage): \(systemError.localizedUIString)")
        }
    }
}

enum TunnelsManagerActivationError: AppError
{
    case activationFailed(wasOnDemandEnabled: Bool)
    case activationFailedWithExtensionError(title: String, message: String, wasOnDemandEnabled: Bool)

    var alertText: AlertText
    {
        switch self
        {
            case .activationFailed(let wasOnDemandEnabled):
                return (alertTunnelActivationFailureTitle, alertTunnelActivationFailureMessage + (wasOnDemandEnabled ? alertTunnelActivationFailureOnDemandAddendum : ""))
            case .activationFailedWithExtensionError(let title, let message, let wasOnDemandEnabled):
                return (title, message + (wasOnDemandEnabled ? alertTunnelActivationFailureOnDemandAddendum : ""))
        }
    }
}

extension Error
{
    var localizedUIString: String
    {
        if let systemError = self as? NEVPNError
        {
            switch systemError
            {
                case NEVPNError.configurationInvalid:
                    return alertSystemErrorMessageTunnelConfigurationInvalid
                case NEVPNError.configurationDisabled:
                    return alertSystemErrorMessageTunnelConfigurationDisabled
                case NEVPNError.connectionFailed:
                    return alertSystemErrorMessageTunnelConnectionFailed
                case NEVPNError.configurationStale:
                    return alertSystemErrorMessageTunnelConfigurationStale
                case NEVPNError.configurationReadWriteFailed:
                    return alertSystemErrorMessageTunnelConfigurationReadWriteFailed
                case NEVPNError.configurationUnknown:
                    return alertSystemErrorMessageTunnelConfigurationUnknown
                default:
                    return ""
            }
        }
        else
        {
            return localizedDescription
        }
    }
}

protocol AppError: Error
{
    typealias AlertText = (title: String, message: String)

    var alertText: AlertText { get }
}
