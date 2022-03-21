//
//  LoggingController.swift
//  Moonbounce
//
//  Created by Mafalda on 5/15/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import Logging
import MoonbounceLibrary
import MoonbounceShared
import MoonbounceNetworkExtensionLibrary
import NetworkExtension

class LoggingController
{
    var loggingEnabled = true
    
    // This allows us to see print statements for debugging
    @objc func startLoggingLoop()
    {
        loggingEnabled = true
        
        guard let vpnPreference = VPNPreferencesController.shared.maybeVPNPreference
        else
        {
            appLog.error("\nUnable to start communications with extension, vpnPreference is nil.\n")
            return
        }
        
        // Send a simple IPC message to the provider, handle the response.
        guard let session = vpnPreference.connection as? NETunnelProviderSession
            else
        {
            appLog.error("\nStart logging loop failed:")
            appLog.error("Unable to send a message, vpnPreference.connection could not be unwrapped as a NETunnelProviderSession.")
            appLog.error("\(vpnPreference.connection)\n")
            return
        }
        
        guard vpnPreference.connection.status != .invalid
            else
        {
            appLog.error("\nInvalid connection status")
            return
        }
        
        DispatchQueue.global(qos: .background).async
        {
            var currentStatus: NEVPNStatus = .invalid
            while self.loggingEnabled
            {
                sleep(1)
                
                if vpnPreference.connection.status != currentStatus
                {
                    currentStatus = vpnPreference.connection.status
                    appLog.debug("\nCurrent Status Changed: \(currentStatus.stringValue)\n")
                    self.updateStatus(state: vpnPreference.connection.status)
                }
                
                guard let message = "Hello Provider".data(using: String.Encoding.utf8)
                    else
                {
                    continue
                }
                
                do
                {
                    try session.sendProviderMessage(message)
                    {
                        response in
                        
                        if response != nil
                        {
                            let responseString: String = NSString(data: response!, encoding: String.Encoding.utf8.rawValue)! as String
                            if responseString != ""
                            {
                                appLog.debug("\(responseString)")
                            }
                        }
                    }
                }
                catch
                {
                    NSLog("Failed to send a message to the provider")
                }
            }
        }
    }
    
    func updateStatus(state: NEVPNStatus)
    {
        switch state
        {
        case .connected:
            isConnected = ConnectState(state: .success, stage: .statusCodes)
        case .connecting:
            isConnected = ConnectState(state: .trying, stage: .statusCodes)
        case .disconnected:
            isConnected = ConnectState(state: .failed, stage: .statusCodes)
        case .disconnecting:
            isConnected = ConnectState(state: .trying, stage: .statusCodes)
        case .invalid:
            isConnected = ConnectState(state: .failed, stage: .statusCodes)
        case .reasserting:
            isConnected = ConnectState(state: .start, stage: .statusCodes)
        default:
            isConnected = ConnectState(state: .failed, stage: .statusCodes)
        }
    }

    func stopLoggingLoop()
    {
        loggingEnabled = false
    }

}
