//
//  Tunnel.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 2/15/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import NetworkExtension
import Replicant
import ReplicantSwift
import Network

//class Tunnel
//{
//    var targetManager: NEVPNManager = NEVPNManager.shared()
//    var name: String?
//    
//    convenience init?(name: String, protocolConfiguration: NETunnelProviderProtocol)
//    {
//        guard let moonbounceConfig = ConfigController.getMoonbounceConfig(fromProtocolConfiguration: protocolConfiguration)
//        else
//        {
//            return nil
//        }
//        
//        self.init(moonbounceConfig: moonbounceConfig)
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                print("Error initializing tunnel model: \(error)")
//            }
//        }
//    }
//    
//    init?(targetManager: NEVPNManager)
//    {
////        guard let protocolConfig = targetManager.protocolConfiguration as? NETunnelProviderProtocol
////        else
////        {
////            print("Attempted to initialize tunnel configuration with a target manager that has no protocol configuration.")
////            return nil
////        }
//        
////        self.init(name: targetManager.localizedDescription ?? "Name Not Provided", protocolConfiguration: protocolConfig)
//        self.targetManager = targetManager
//        self.name = targetManager.localizedDescription
//    }
//    
//    init(moonbounceConfig: MoonbounceConfig, completionHandler: @escaping ((Error?) -> Void))
//    {
//        let newManager = NETunnelProviderManager()
//        
//        newManager.loadFromPreferences
//        {
//            (maybeError) in
//        
//            if let error = maybeError
//            {
//                print("\nError loading from preferences!\(error)\n")
//                completionHandler(error)
//                return
//            }
//            
//            let protocolConfiguration: NETunnelProviderProtocol = NETunnelProviderProtocol()
//            let appId = Bundle.main.bundleIdentifier!
//            print("\n----->Setting the providerBundleIdentifier to \(appId).NetworkExtension")
//            protocolConfiguration.providerBundleIdentifier = "\(appId).NetworkExtension"
//            protocolConfiguration.serverAddress = "\(moonbounceConfig.clientConfig.host)"
//            newManager.localizedDescription = moonbounceConfig.name
//            newManager.isEnabled = true
//            
//            guard let clientConfigJSON = moonbounceConfig.clientConfig.createJSON()
//                else
//            {
//                return
//            }
//            
//            if moonbounceConfig.replicantConfig != nil
//            {
//                guard let replicantConfigJSON = moonbounceConfig.replicantConfig!.createJSON()
//                    else
//                {
//                    return
//                }
//                
//                protocolConfiguration.providerConfiguration = [
//                    Keys.clientConfigKey.rawValue: clientConfigJSON,
//                    Keys.replicantConfigKey.rawValue: replicantConfigJSON,
//                    Keys.tunnelNameKey.rawValue: moonbounceConfig.name]
//                print("\nproviderConfiguration: \(protocolConfiguration.providerConfiguration!)\n")
//            }
//            else
//            {
//                protocolConfiguration.providerConfiguration = [Keys.clientConfigKey.rawValue: clientConfigJSON]
//            }
//            
//            newManager.protocolConfiguration = protocolConfiguration
//            
//            newManager.saveToPreferences
//            {
//                maybeError in
//                
//                guard maybeError == nil
//                    else
//                {
//                    print("\nFailed to save the configuration: \(maybeError!)\n")
//                    completionHandler(maybeError)
//                    return
//                }
//                
//                newManager.loadFromPreferences(completionHandler:
//                {
//                    (maybeError) in
//                    
//                    if let error = maybeError
//                    {
//                        print("\nError loading from preferences!\(error)\n")
//                        completionHandler(error)
//                        return
//                    }
//                    
//                    self.targetManager = newManager
//                    self.name = moonbounceConfig.name
//                    completionHandler(nil)
//                })
//            }
//       }
//    }
//    
//
//    
//    /// Dev purposes only! Creates a demo tunnel.
////    init(completionHandler: @escaping ((Error?) -> Void))
////    {
////        let newManager = NETunnelProviderManager()
////        newManager.protocolConfiguration = NETunnelProviderProtocol()
////        newManager.localizedDescription = "Demo VPN"
////        newManager.protocolConfiguration?.serverAddress = "127.0.0.1"
////        newManager.isEnabled = true
////
////        newManager.saveToPreferences
////        {
////            maybeError in
////
////            guard maybeError == nil
////                else
////            {
////                print("\nFailed to save the configuration: \(maybeError!)\n")
////                completionHandler(maybeError)
////                return
////            }
////
////            newManager.loadFromPreferences(completionHandler:
////            {
////                (maybeError) in
////
////                if let error = maybeError
////                {
////                    print("\nError loading from preferences!\(error)\n")
////                    completionHandler(error)
////                    return
////                }
////
////                self.targetManager = newManager
////                completionHandler(nil)
////            })
////        }
////    }
//
//}

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
