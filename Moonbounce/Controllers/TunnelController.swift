//
//  TunnelController.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 2/15/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

//import Foundation
//import NetworkExtension
//import ReplicantSwift
//
//class TunnelController
//{
//    var tunnels = [Tunnel]()
//    var defaultTunnel: Tunnel?
//
//    init()
//    {
//        reloadTunnels
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                appLog.error("\nreceived an error while loading tunnels: \(error)\n")
//            }
//        }
//    }
//
//    func reloadTunnels(completionHandler:@escaping ((Error?) -> Void))
//    {
//        NETunnelProviderManager.loadAllFromPreferences()
//        {
//            newManagers, error in
//
//            guard let vpnManagers = newManagers
//                else
//            {
//                appLog.error("We think newManagers from load preferences is nil: \(String(describing: newManagers))")
//                return
//
//            }
//
//            for manager in vpnManagers
//            {
//                if let tunnel = Tunnel(targetManager: manager)
//                {
//                    if let tunnelName = tunnel.name, tunnelName == defaultTunnelName
//                    {
//                        self.defaultTunnel = tunnel
//                    }
//                    else
//                    {
//                        self.tunnels.append(tunnel)
//                    }
//                }
//            }
//
//            if self.defaultTunnel == nil
//            {
//                self.addDefaultTunnel(completionHandler:
//                {
//                    (maybeError) in
//
//                    if let error = maybeError
//                    {
//                        appLog.error("\nUnable to add the default tunnel: \(error)")
//                    }
//                })
//            }
//
//            completionHandler(error)
//        }
//    }
//
//    func removeTunnel(atIndex index: Int, completionHandler:@escaping ((Error?) -> Void))
//    {
//        guard index < tunnels.count
//        else
//        {
//            completionHandler(nil)
//            return
//        }
//
//        let tunnel = tunnels[index]
//        tunnel.targetManager.removeFromPreferences
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                appLog.error("\nError removing tunnel from preferences: \n\(error)\n")
//                return
//            }
//
//            self.tunnels.remove(at: index)
//            self.reloadTunnels(completionHandler:{_ in })
//            completionHandler(maybeError)
//        }
//    }
//
//    func addTunnel(moonbounceConfig: MoonbounceConfig, completionHandler: @escaping (Error?) -> Void)
//    {
//        let _ = Tunnel(moonbounceConfig: moonbounceConfig, completionHandler:
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                appLog.error("\nreceived an error creating a demo tunnel: \(error)\n")
//                return
//            }
//
//            self.reloadTunnels(completionHandler:
//            {
//                (maybeError) in
//
//                completionHandler(maybeError)
//            })
//        })
//
//    }
//
//    func addDefaultTunnel(completionHandler:@escaping ((Error?) -> Void))
//    {
//        let fileManager = FileManager.default
//        guard let configController = ConfigController()
//        else
//        {
//            appLog.error("Unable to create default config: Config controller was not initialized correctly.")
//            //FIXME: Add error
//            completionHandler(nil)
//            return
//        }
//
//        guard let dDirectory = configController.get(configDirectory: .defaultDirectory)
//        else
//        {
//            appLog.error("Unable to get default directory.")
//            return
//        }
//
//
//        if fileManager.fileExists(atPath: dDirectory.path)
//        {
//            do
//            {
//                try fileManager.removeItem(at: dDirectory)
//            }
//            catch let error
//            {
//                appLog.error("Error deleting files in default directory: \(error)")
//            }
//        }
//
//         guard let moonbounceZip = Bundle.main.url(forResource: "default.moonbounce", withExtension: nil)
//        else
//         {
//            appLog.error("\nUnable to find the default config file in the bundle")
//            return
//        }
//
//        do
//        {
//            try fileManager.unzipItem(at: moonbounceZip, to: dDirectory, progress: nil)
//            do {
//                let defaultDirectory = dDirectory.appendingPathComponent("Default")
//                 let files = try fileManager.contentsOfDirectory(atPath: defaultDirectory.path)
//                appLog.debug(files)
//            } catch let error {
//                appLog.error("error listing contents of default directory: \(error)")
//            }
//
//            let defaultDirectory = dDirectory.appendingPathComponent("Default")
//            if let moonbounceConfig = configFilesAreValid(atURL: defaultDirectory)
//            {
//                let _ = Tunnel(moonbounceConfig: moonbounceConfig)
//                {
//                    (maybeError) in
//
//                    if let error = maybeError
//                    {
//                        appLog.error("\nError creating tunnel: \(error)")
//
//                    }
//
//                    self.reloadTunnels(completionHandler:
//                    {
//                        (maybeError) in
//
//                        completionHandler(maybeError)
//                    })
//                }
//            }
//        }
//        catch let error
//        {
//            appLog.error("Error unzipping item: \(error)")
//            return
//        }
//    }
//
//    func configFilesAreValid(atURL configURL: URL) -> MoonbounceConfig?
//    {
//        do
//        {
//            let fileManager = FileManager.default
//            if let fileEnumerator = fileManager.enumerator(at: configURL,
//                                                           includingPropertiesForKeys: [.nameKey],
//                                                           options: [.skipsHiddenFiles],
//                                                           errorHandler:
//                {
//                    (url, error) -> Bool in
//
//                    appLog.error("File enumerator error at \(configURL.path): \(error.localizedDescription)")
//                    return true
//            })
//            {
//                //Verify  that each of the following files are present as all config files are neccessary for successful connection:
//                let file1 = "replicantclient.config"
//                let file2 = "replicant.config"
//
//                var fileNames = [String]()
//                for case let fileURL as URL in fileEnumerator
//                {
//                    let fileName = try fileURL.resourceValues(forKeys: Set([.nameKey]))
//
//                    if fileName.name != nil
//                    {
//                        fileNames.append(fileName.name!)
//                    }
//                }
//
//                //If all required files are present refresh server select button
//                if fileNames.contains(file1)
//                {
//                    guard let clientConfig = ClientConfig(withConfigAtPath: configURL.appendingPathComponent(file1).path)
//
//                        else
//                    {
//                        appLog.error("Unable to create replicant config from file at \(configURL.appendingPathComponent(file1))")
//
//                        return nil
//                    }
//
//                    let replicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(file2).path)
//
//                    let moonbounceConfig = MoonbounceConfig(name: configURL.lastPathComponent, clientConfig: clientConfig, replicantConfig: replicantConfig)
//
//
//                    return moonbounceConfig
//                }
//            }
//        }
//        catch
//        {
//            return nil
//        }
//
//        return nil
//    }
////    func addDemoTunnel(completionHandler:@escaping ((Error?) -> Void))
////    {
////        guard tunnels.isEmpty
////        else
////        {
////            appLog.error("\nNot creating demo tunnel as \(tunnels.count) tunnels already exist.\n")
////            for tunnel in tunnels
////            {
////                appLog.error(tunnel.targetManager.localizedDescription ?? "Unnamed Tunnel")
////                appLog.error(tunnel.targetManager.protocolConfiguration ?? "No Protocol Config\n")
////            }
////
////            return
////        }
////
////        _ = Tunnel
////        {
////            (maybeError) in
////
////            if let error = maybeError
////            {
////                appLog.error("\nreceived an error creating a demo tunnel: \(error)\n")
////                return
////            }
////
////            self.reloadTunnels(completionHandler:
////            {
////                (maybeError) in
////
////                completionHandler(maybeError)
////            })
////        }
////    }
//}
