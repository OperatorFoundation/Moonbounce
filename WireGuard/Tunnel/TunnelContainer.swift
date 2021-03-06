//
//  TunnelContainer.swift
//  Moonbounce
//
//  Created by Mafalda on 2/5/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation
import NetworkExtension

class TunnelContainer: NSObject
{
    @objc dynamic var name: String
    @objc dynamic var status: TunnelStatus
    @objc dynamic var isActivateOnDemandEnabled: Bool

    var activationAttemptId: String?
    var activationTimer: Timer?
    var tunnelProvider: NETunnelProviderManager
    var lastTunnelConnectionStatus: NEVPNStatus?
    var tunnelConfiguration: TunnelConfiguration
    var loggingEnabled = false
    
    var activateOnDemandSetting: ActivateOnDemandSetting
    {
        return ActivateOnDemandSetting(from: tunnelProvider)
    }
    
    var isAttemptingActivation = false
    {
        didSet
        {
            if isAttemptingActivation
            {
                self.activationTimer?.invalidate()
                let activationTimer = Timer(timeInterval: 5 /* seconds */, repeats: true)
                {
                    [weak self] _ in
                    
                    guard let self = self
                        else { return }
                    
                    print("Status update notification timeout for tunnel '\(self.name)'. Tunnel status is now '\(self.tunnelProvider.connection.status)'.")
                    
                    switch self.tunnelProvider.connection.status
                    {
                        case .connected, .disconnected, .invalid:
                            self.activationTimer?.invalidate()
                            self.activationTimer = nil
                        default:
                            break
                    }
                    
                    self.refreshStatus()
                }
                
                self.activationTimer = activationTimer
                RunLoop.main.add(activationTimer, forMode: .default)
            }
        }
    }
    
    init?(tunnel: NETunnelProviderManager)
    {
        let currentStatus = TunnelStatus(from: tunnel.connection.status)

        name = tunnel.localizedDescription ?? "Unnamed"
        status = currentStatus
        isActivateOnDemandEnabled = tunnel.isOnDemandEnabled
        tunnelProvider = tunnel
        
        guard let protocolConfiguration = tunnelProvider.protocolConfiguration as? NETunnelProviderProtocol
            else
        {
            print("\nUnable to initialize tunnel container: Protocol Configuration is nil.\n")
            return nil
        }
        
        guard let tunnelConfig = TunnelConfiguration(name: tunnel.localizedDescription ?? "Unnamed", providerProtocol: protocolConfiguration)
        else
        {
            return nil
        }
        
        tunnelConfiguration = tunnelConfig
        
        super.init()
    }
    
    func refreshStatus() {
        let status = TunnelStatus(from: tunnelProvider.connection.status)
        self.status = status
        isActivateOnDemandEnabled = tunnelProvider.isOnDemandEnabled
    }
    
    func startActivation(recursionCount: UInt = 0, lastError: Error? = nil, activationDelegate: TunnelsManagerActivationDelegate?)
    {
        if recursionCount >= 8
        {
            wg_log(.error, message: "startActivation: Failed after 8 attempts. Giving up with \(lastError!)")
            activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedBecauseOfTooManyErrors(lastSystemError: lastError!))
            return
        }
        
        print( "startActivation: Entering (tunnel: \(name))")
        
        // Ensure that no other tunnel can attempt activation until this tunnel is done trying
        status = .activating
        
        guard tunnelProvider.isEnabled
            else
        {
            // In case the tunnel had gotten disabled, re-enable and save it,
            // then call this function again.
            print("startActivation: Tunnel is disabled. Re-enabling and saving")
            //tunnelProvider.isEnabled = false //FIXME
            
            tunnelProvider.loadFromPreferences
            {
                (maybeError) in
                
                if let error = maybeError
                {
                    print("Error loading from preferences: \(error)")
                    activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileLoading(systemError: error))
                    return
                }
                // MARK: - This is where we pass our parameters to the extension
                self.tunnelProvider.localizedDescription = "MoonbounceTest"
                self.tunnelProvider.isEnabled = true
                
                self.tunnelProvider.saveToPreferences
                {
                    [weak self] error in
                    
                    guard let self = self else { return }
                    
                    if error != nil
                    {
                        print("Error saving tunnel after re-enabling: \(error!)")
                        activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileSaving(systemError: error!))
                        return
                    }
                    print("startActivation: Tunnel saved after re-enabling, invoking startActivation")
                    self.startActivation(recursionCount: recursionCount + 1, lastError: NEVPNError(NEVPNError.configurationUnknown), activationDelegate: activationDelegate)
                }
            }
            
            return
        }
        
        // Start the tunnel
        tunnelProvider.loadFromPreferences
        {
            maybeError in
            
            if let error = maybeError
            {
                print("Error loading from preferences: \(error)")
                activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileLoading(systemError: error))
                return
            }
            
            self.tunnelProvider.saveToPreferences
            {
                maybeSaveError in
                
                if let saveError = maybeSaveError
                {
                    print("Error saving tunnel after re-enabling: \(saveError)")
                    activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileSaving(systemError: saveError))
                    return
                }
                
                do
                {
                    print("startActivation: Starting tunnel")
                    
                    self.isAttemptingActivation = true
                    let activationAttemptId = UUID().uuidString
                    self.activationAttemptId = activationAttemptId
                    
                    self.startLoggingLoop()
                    
                    //TODO: Needs to pass configs to the Network Extension
                    //try (tunnelProvider.connection as? NETunnelProviderSession)?.startTunnel(options: ["activationAttemptId": activationAttemptId])
                    
                    print("\nCalling startVPNTunnel on \(self.tunnelProvider.connection)\n")
                    try self.tunnelProvider.connection.startVPNTunnel()
                    
                    print("startActivation: Success")
                    activationDelegate?.tunnelActivationAttemptSucceeded(tunnel: self)
                }
                catch let error
                {
                    self.isAttemptingActivation = false
                    guard let systemError = error as? NEVPNError
                        else
                    {
                        print("Failed to activate tunnel: Error: \(error)")
                        
                        self.status = .inactive
                        activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileStarting(systemError: error))
                        return
                    }
                    guard systemError.code == NEVPNError.configurationInvalid || systemError.code == NEVPNError.configurationStale
                        else
                    {
                        print("Failed to activate tunnel: VPN Error: \(error)")
                        
                        self.status = .inactive
                        activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileStarting(systemError: systemError))
                        return
                    }
                    
                    print("\nError trying to start tunnel: \(systemError.localizedDescription)")
                    print("startActivation: Will reload tunnel and then try to start it.")
                    
                    self.tunnelProvider.loadFromPreferences
                        {
                            [weak self] error in
                            
                            guard let self = self
                                else { return }
                            
                            if error != nil
                            {
                                print("startActivation: Error reloading tunnel: \(error!)")
                                self.status = .inactive
                                activationDelegate?.tunnelActivationAttemptFailed(tunnel: self, error: .failedWhileLoading(systemError: systemError))
                                return
                            }
                            
                            print("startActivation: Tunnel reloaded, invoking startActivation")
                            self.startActivation(recursionCount: recursionCount + 1, lastError: systemError, activationDelegate: activationDelegate)
                    }
                }
            }
        }
    }
    
    func startDeactivation()
    {
        (tunnelProvider.connection as? NETunnelProviderSession)?.stopTunnel()
    }
    
    @objc func startLoggingLoop()
    {
        loggingEnabled = true
        
        // Send a simple IPC message to the provider, handle the response.
        guard let session = self.tunnelProvider.connection as? NETunnelProviderSession
            else
        {
            print("\nUnable to begin logging, no session was found.")
            return
        }
        
        guard self.tunnelProvider.connection.status != .invalid
            else
        {
            print("\nInvalid connection status")
            return
        }
        
        DispatchQueue.global(qos: .background).async
        {
            var currentStatus = "Unknown"

            while self.loggingEnabled
            {
                sleep(1)
                
                if self.tunnelProvider.connection.status.debugDescription != currentStatus
                {
                    currentStatus = self.tunnelProvider.connection.status.debugDescription
                    print("\nCurrent Status Changed: \(currentStatus)\n")
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
                                print(responseString)
                            }
                        }
                        else
                        {
                            print("Got a nil response from the provider")
                        }
                    }
                }
                catch
                {
                    print("Failed to send a message to the provider")
                }
                
                DispatchQueue.main.async
                {
                    // Stub
                }
            }
        }
    }
    
    func stopLoggingLoop()
    {
        loggingEnabled = false
    }
}
