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
    
    func setup(moonbounceConfig: MoonbounceConfig, completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
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
                self.updateConfiguration(moonbounceConfig: moonbounceConfig)
                {
                    (maybeError) in
                    
                    if let error = maybeError
                    {
                        completionHandler(Either<NETunnelProviderManager>.error(error))
                        return
                    }
                    else
                    {
                        completionHandler(Either<NETunnelProviderManager>.value(vpnPreference))
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
            setup(moonbounceConfig: moonbounceConfig)
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
    
    private func updateConfiguration(vpnPreference: NETunnelProviderManager, moonbounceConfig: MoonbounceConfig, isEnabled: Bool = true, completionHandler: @escaping ((Error?) -> Void))
    {
        guard let protocolConfiguration = self.newProtocolConfiguration(moonbounceConfig: moonbounceConfig)
        else
        {
            completionHandler(VPNPreferencesError.protocolConfiguration)
            return
        }
        
        vpnPreference.protocolConfiguration = protocolConfiguration
        vpnPreference.localizedDescription = moonbounceConfig.name
        vpnPreference.isEnabled = isEnabled
        
        self.save(completionHandler: completionHandler)
    }
    
    func deactivate(completionHandler: @escaping ((Error?) -> Void))
    {
        if let vpnPreference = maybeVPNPreference
        {
            vpnPreference.isEnabled = false
            save(vpnPreference: vpnPreference, completionHandler: completionHandler)
        }
        else
        {
            completionHandler(VPNPreferencesError.nilVPNPreference)
        }
    }

    func load(completionHandler: @escaping ((Either<NETunnelProviderManager>) -> Void))
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
    
    func save(completionHandler: @escaping ((Error?) -> Void))
    {
        guard let vpnPreference = maybeVPNPreference
        else
        {
            completionHandler(VPNPreferencesError.nilVPNPreference)
            return
        }
        
        save(vpnPreference: vpnPreference, completionHandler: completionHandler)
    }
    
    func save(vpnPreference: NETunnelProviderManager, completionHandler: @escaping ((Error?) -> Void))
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
    
    func newProtocolConfiguration(moonbounceConfig: MoonbounceConfig) -> NETunnelProviderProtocol?
    {
        let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
        let appId = Bundle.main.bundleIdentifier!
        print("\n----->Setting the providerBundleIdentifier to \(appId).NetworkExtension")
        protocolConfiguration.providerBundleIdentifier = "\(appId).NetworkExtension"
        protocolConfiguration.serverAddress = "\(moonbounceConfig.clientConfig.host)"
        protocolConfiguration.includeAllNetworks = true
        
        guard let clientConfigJSON = moonbounceConfig.clientConfig.createJSON()
            else
        {
            return nil
        }

        // FIXME: Replicant JSON needed here
        
//        if moonbounceConfig.replicantConfig != nil
//        {
//            guard let replicantConfigJSON = moonbounceConfig.replicantConfig!.createJSON()
//                else
//            {
//                return nil
//            }
//
//            protocolConfiguration.providerConfiguration = [
//                Keys.clientConfigKey.rawValue: clientConfigJSON,
//                Keys.replicantConfigKey.rawValue: replicantConfigJSON,
//                Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
//
//            print("\nproviderConfiguration: \(protocolConfiguration.providerConfiguration!)\n")
//        }
//        else
//        {
//            protocolConfiguration.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfigJSON]
//        }
        
        let replicantConfigString = "{}"
        protocolConfiguration.providerConfiguration = [
                        Keys.clientConfigKey.rawValue: clientConfigJSON,
                        Keys.replicantConfigKey.rawValue: replicantConfigString.data,
                        Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
                
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


