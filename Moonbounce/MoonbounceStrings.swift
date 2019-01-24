//
//  MoonbounceStrings.swift
//  Moonbounce
//
//  Created by Adelita Schule on 1/8/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation

//MARK: Alerts
let alertTunnelNameEmptyTitle = "Tunnel Name Missing"
let alertTunnelNameEmptyMessage = "Please enter a name for this tunnel."

let alertTunnelAlreadyExistsWithThatNameTitle = "Tunnel Name Unavailable"
let alertTunnelAlreadyExistsWithThatNameMessage = "There is already a tunnel with this name. Please choose a different name."

let alertSystemErrorOnListingTunnelsTitle = "Unable to List Tunnels"
let alertErrorOnListingTunnelsMessage = "Unable to list tunnels, no tunnel information was found."
let alertSystemErrorOnAddTunnelTitle = "Unable to Add Tunnel"
let alertSystemErrorOnModifyTunnelTitle = "Unable to Modify Tunnel"
let alertSystemErrorOnRemoveTunnelTitle = "Unable to Remove Tunnel"

let alertTunnelActivationErrorTunnelIsNotInactiveTitle = "Tunnel Already Active"
let alertTunnelActivationErrorTunnelIsNotInactiveMessage = "Unable to activate this tunnel as it is already active."

let alertTunnelActivationSystemErrorTitle = "Unable to Activate Tunnel: System Error"
let alertTunnelActivationSystemErrorMessage = "Received an error while attempting to activate a tunnel: (%@)" //systemError.localizedUIString

let alertTunnelActivationFailureTitle = "Failed to Activate Tunnel"
let alertTunnelActivationFailureMessage = "Tunnel activation failed."
let alertTunnelActivationFailureOnDemandAddendum = "On Demand was enabled"
let alertTunnelActivationSavedConfigFailureMessage = "There is something wrong with the saved configuration."
let alertTunnelDNSFailureTitle = "Tunnel DNS Failure"
let alertTunnelDNSFailureMessage = "There was an error resolving the DNS"
let alertTunnelActivationBackendFailureMessage = "Could not start the back end."
let alertTunnelActivationFileDescriptorFailureMessage = "There was an issue determining the file descriptor."
let alertTunnelActivationSetNetworkSettingsMessage = "We were unable to set the network settings."

let alertSystemErrorMessageTunnelConfigurationInvalid = "The tunnel configuration is invalid."
let alertSystemErrorMessageTunnelConfigurationDisabled = "The tunnel configuration has been disabled."
let alertSystemErrorMessageTunnelConnectionFailed = "The tunnel connection failed."
let alertSystemErrorMessageTunnelConfigurationStale = "The tunnel configuration is stale."
let alertSystemErrorMessageTunnelConfigurationReadWriteFailed = "Unable to read/write the tunnel configuration."
let alertSystemErrorMessageTunnelConfigurationUnknown = "The tunnel configuration is unknown."
