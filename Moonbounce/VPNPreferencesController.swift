//
//  VPNPreferencesController.swift
//  Moonbounce
//
//  Created by Mafalda on 4/14/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import NetworkExtension

/// All of these functions must be called from the main thread
class VPNPreferencesController
{
    static let shared = VPNPreferencesController()
    
    var maybeVPNPreference: NETunnelProviderManager?
    
    // MARK: Public Functions
    
    func setup(completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
    {
        // Doing this because we believe NetworkExtension requires it
        load
        {
           (eitherVPNPreference) in
            
            switch eitherVPNPreference
            {
            case .error(_):
                completionHandler(eitherVPNPreference)
                return
            case .value(let vpnPreference):
                self.save(vpnPreference: vpnPreference)
                {
                    (maybeError) in
                    
                    guard maybeError == nil
                    else
                    {
                        if let error = maybeError
                        {
                            completionHandler(.error(error))
                            return
                        }
                        else
                        {
                            completionHandler(.error(VPNPreferencesError.unexpectedNilValue))
                            return
                        }
                    }
                    
                    self.load
                    {
                        (nextEitherVPNPreference) in
                        
                        completionHandler(nextEitherVPNPreference)
                        return
                    }
                }
            }
        }
    }
    
    func updateConfiguration(moonbounceConfig: MoonbounceConfig, isEnabled: Bool = false, completionHandler: @escaping ((Error?) -> Void))
    {
        if let vpnPreference = maybeVPNPreference
        {
            updateConfiguration(vpnPreference: vpnPreference, moonbounceConfig: moonbounceConfig, completionHandler: completionHandler)
        }
        else
        {
            setup
            {
                (eitherVPNPreference) in
                
                switch eitherVPNPreference
                {
                case .error(let error):
                    completionHandler(error)
                    return
                case .value(let vpnPreference):
                    self.maybeVPNPreference = vpnPreference
                    self.updateConfiguration(vpnPreference: vpnPreference, moonbounceConfig: moonbounceConfig, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func updateConfiguration(vpnPreference: NETunnelProviderManager, moonbounceConfig: MoonbounceConfig, isEnabled: Bool = false, completionHandler: @escaping ((Error?) -> Void))
    {
        guard let protocolConfiguration = self.newProtocolConfiguration(moonbounceConfig: moonbounceConfig)
        else
        {
            completionHandler(VPNPreferencesError.protocolConfiguration)
            return
        }
        
        vpnPreference.localizedDescription = moonbounceConfig.name
        vpnPreference.isEnabled = isEnabled
        vpnPreference.protocolConfiguration = protocolConfiguration
        
        self.save(completionHandler: completionHandler)
    }
    
    func activate(completionHandler: @escaping ((Error?) -> Void))
    {
        if let vpnPreference = maybeVPNPreference
        {
            activate(vpnPreference: vpnPreference, completionHandler: completionHandler)
        }
        else
        {
            setup
            {
                (eitherVPNPreference) in
                
                switch eitherVPNPreference
                {
                case .error(let error):
                    completionHandler(error)
                    return
                case .value(let vpnPreference):
                    self.maybeVPNPreference = vpnPreference
                    self.activate(vpnPreference: vpnPreference, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func activate(vpnPreference: NETunnelProviderManager, completionHandler: @escaping ((Error?) -> Void))
    {
        vpnPreference.isEnabled = true
        save(completionHandler: completionHandler)
    }
    
    func deactivate(completionHandler: @escaping ((Error?) -> Void))
    {
        if let vpnPreference = maybeVPNPreference
        {
            deactivate(vpnPreference: vpnPreference, completionHandler: completionHandler)
        }
        else
        {
            setup
            {
                (eitherVPNPreference) in
                
                switch eitherVPNPreference
                {
                case .error(let error):
                    completionHandler(error)
                    return
                case .value(let vpnPreference):
                    self.maybeVPNPreference = vpnPreference
                    self.deactivate(vpnPreference: vpnPreference, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func deactivate(vpnPreference: NETunnelProviderManager, completionHandler: @escaping ((Error?) -> Void))
    {
        vpnPreference.isEnabled = false
        save(vpnPreference: vpnPreference, completionHandler: completionHandler)
    }
    
    // MARK: Private Functions
    
    private func load(completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
    {
        let newManager = NETunnelProviderManager()

         newManager.loadFromPreferences
         {
             (maybeError) in
         
             if let error = maybeError
             {
                 print("\nError loading from preferences!\(error)\n")
                
                self.maybeVPNPreference = nil
                completionHandler(.error(error))
                return
             }
            
            self.maybeVPNPreference = newManager
            completionHandler(.value(newManager))
            return
        }
    }
    
    private func save(completionHandler: @escaping ((Error?) -> Void))
    {
        guard let vpnPreference = maybeVPNPreference
        else
        {
            completionHandler(VPNPreferencesError.nilVPNPreference)
            return
        }
        
        save(vpnPreference: vpnPreference, completionHandler: completionHandler)
    }
    
    private func save(vpnPreference: NETunnelProviderManager, completionHandler: @escaping ((Error?) -> Void))
    {
        vpnPreference.saveToPreferences
        {
            maybeError in
            
            guard maybeError == nil
                else
            {
                print("\nFailed to save the configuration: \(maybeError!)\n")
                completionHandler(maybeError)
                return
            }
            
            vpnPreference.loadFromPreferences(completionHandler:
            {
                (maybeError) in
                
                if let error = maybeError
                {
                    print("\nError loading from preferences!\(error)\n")
                    completionHandler(error)
                    return
                }
                
                completionHandler(nil)
            })
        }
    }
    
    private func newProtocolConfiguration(moonbounceConfig: MoonbounceConfig) -> NETunnelProviderProtocol?
    {
        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        let appId = Bundle.main.bundleIdentifier!
        print("\n----->Setting the providerBundleIdentifier to \(appId).NetworkExtension")
        protocolConfiguration.providerBundleIdentifier = "\(appId).NetworkExtension"
        protocolConfiguration.serverAddress = "\(moonbounceConfig.clientConfig.host)"
        
        guard let clientConfigJSON = moonbounceConfig.clientConfig.createJSON()
            else
        {
            return nil
        }
        
        if moonbounceConfig.replicantConfig != nil
        {
            guard let replicantConfigJSON = moonbounceConfig.replicantConfig!.createJSON()
                else
            {
                return nil
            }
            
            protocolConfiguration.providerConfiguration = [
                Keys.clientConfigKey.rawValue: clientConfigJSON,
                Keys.replicantConfigKey.rawValue: replicantConfigJSON,
                Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
            
            print("\nproviderConfiguration: \(protocolConfiguration.providerConfiguration!)\n")
        }
        else
        {
            protocolConfiguration.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfigJSON]
        }
        
        return protocolConfiguration
    }
    
    
    
}

enum VPNPreferencesError: Error
{
    case protocolConfiguration
    case nilVPNPreference
    case unexpectedNilValue
    
    var localizedDescription: String
    {
        switch self
        {
            
        case .protocolConfiguration:
            return NSLocalizedString("Failed to initialize a NETunnelProviderProtocol", comment: "")
        case .nilVPNPreference:
            return NSLocalizedString("Cannot save a nil preference.", comment: "")
        case .unexpectedNilValue:
            return NSLocalizedString("We got a nil value that should be impossible.", comment: "")
        }
    }
}

enum Either<Value>
{
    case value(Value)
    case error(Error)
}


