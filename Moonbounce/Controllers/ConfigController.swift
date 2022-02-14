//
//  configController.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 1/18/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import NetworkExtension
import ZIPFoundation
import ReplicantSwift

class ConfigController
{
    let fileManager = FileManager.default
    var configs = [MoonbounceConfig]()
    
    func getDefaultMoonbounceConfig()-> MoonbounceConfig?
    {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: defaultConfigDirectory.path)
        {
            do
            {
                try fileManager.removeItem(at: defaultConfigDirectory)
            }
            catch let error
            {
                appLog.error("Error deleting files in default directory: \(error)")
            }
        }
        
        if fileManager.fileExists(atPath: configFilesDirectory.appendingPathComponent("/__MACOSX").path)
        {
            do
            {
                try fileManager.removeItem(at: configFilesDirectory.appendingPathComponent("/__MACOSX"))
            }
            catch let error
            {
                appLog.error("Error deleting files in default directory: \(error)")
            }
        }

        guard let moonbounceZip = Bundle.main.url(forResource: "default.moonbounce", withExtension: nil)
        else
         {
            appLog.error("\nUnable to find the default config file in the bundle")
            return nil
        }

        do
        {
            try fileManager.unzipItem(at: moonbounceZip, to: configFilesDirectory, progress: nil)
            
            // Print for debug use only
            do
            {
                 let files = try fileManager.contentsOfDirectory(atPath: defaultConfigDirectory.path)
                appLog.debug("\(files)")
            }
            catch let error
            {
                appLog.error("error listing contents of default directory: \(error)")
            }

            if let moonbounceConfig = createMoonbounceConfigFromFiles(atURL: defaultConfigDirectory)
            {
                return moonbounceConfig
            }
        }
        catch let error
        {
            appLog.error("Error unzipping item: \(error)")
            return nil
        }
        
        return nil
    }
    
    func addConfig(atURL url: URL) -> Bool
    {
        let configName = fileManager.displayName(atPath: url.path)
            //url.deletingPathExtension().lastPathComponent
        let thisConfigURL = url.appendingPathComponent(configName)
        
        guard let importDirectory = get(configDirectory: .importedDirectory)
        else
        {
            appLog.error("Unable to get the config directory")
            return false
        }

            
            if configFilesAreValid(atURL: thisConfigURL)
            {
                return true
            }
            else
            {
                do
                {
                    try fileManager.unzipItem(at: url, to: importDirectory, progress: nil)
                    
                    if configFilesAreValid(atURL: thisConfigURL)
                    {
                        return true
                    }
                }
                catch let error
                {
                    appLog.error("Error unzipping item: \(error)")
                    return false
                }
            }

        
        return false
    }
    
    func removeConfig(atURL url: URL) -> Bool
    {
        do
        {
            try FileManager.default.removeItem(at: url)
            return true
        }
        catch let error
        {
            appLog.error("\nError deleting config at \(url): \(error)\n")
            return false
        }
    }
    
    func configFilesAreValid(atURL configURL: URL) -> Bool
    {
        do
        {
            let fileManager = FileManager.default
            if let fileEnumerator = fileManager.enumerator(at: configURL,
                                                           includingPropertiesForKeys: [.nameKey],
                                                           options: [.skipsHiddenFiles],
                                                           errorHandler:
            {
                (url, error) -> Bool in
                
                appLog.error("File enumerator error at \(configURL.path): \(error.localizedDescription)")
                return true
            })
            {
                //Verify  that each of the following files are present as all config files are neccessary for successful connection:
                let file1 = "replicantClient.config"
                let file2 = "replicant.config"
                
                var fileNames = [String]()
                for case let fileURL as URL in fileEnumerator
                {
                    let fileName = try fileURL.resourceValues(forKeys: Set([.nameKey]))
                    if fileName.name != nil
                    {
                        fileNames.append(fileName.name!)
                    }
                }
                
                //If all required files are present refresh server select button
                if fileNames.contains(file1)
                {
                    guard let clientConfig = ClientConfig(withConfigAtPath: configURL.appendingPathComponent(file2).path)
                        
                    else
                    {
                        appLog.error("Unable to create replicant config from file at \(configURL.appendingPathComponent(file1))")
                        
                        return false
                    }
                    
                    // FIXME: Replicant Config from JSON
                    //let replicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(file1).path)
                    let replicantConfig: ReplicantConfig? = nil
                    let moonbounceConfig = MoonbounceConfig(name: configURL.lastPathComponent, clientConfig: clientConfig, replicantConfig: replicantConfig)
                    
                    self.configs.append(moonbounceConfig)
                    
                    return true
                }
            }
        }
        catch
        {
            return false
        }
        
        return false
    }
    
    func get(configDirectory: ConfigDirectory) -> URL?
    {
        let thisDirectory = configFilesDirectory.appendingPathComponent(configDirectory.rawValue)
        
        do
        {
            try fileManager.createDirectory(at: thisDirectory, withIntermediateDirectories: true, attributes: nil)
            return thisDirectory
        }
        catch let error
        {
            appLog.error("Error creating \(configDirectory.rawValue): \(error)")
            return nil
        }
    }
    
    func createMoonbounceConfigFromFiles(atURL configURL: URL) -> MoonbounceConfig?
    {
        do
        {
            let fileManager = FileManager.default
            if let fileEnumerator = fileManager.enumerator(at: configURL,
                                                           includingPropertiesForKeys: [.nameKey],
                                                           options: [.skipsHiddenFiles],
                                                           errorHandler:
            {
                (url, error) -> Bool in
                
                appLog.error("File enumerator error at \(configURL.path): \(error.localizedDescription)")
                return true
            })
            {
                //Verify  that each of the following files are present as all config files are neccessary for successful connection:
                let clientConfigFilename = "replicantclient.config"
                let replicantConfigFilename = "replicant.config"
                //let file2 = "replicant.config"
                
                var fileNames = [String]()
                for case let fileURL as URL in fileEnumerator
                {
                    let fileName = try fileURL.resourceValues(forKeys: Set([.nameKey]))
                    
                    if fileName.name != nil
                    {
                        fileNames.append(fileName.name!)
                    }
                }
                
                //If all required files are present refresh server select button
                if fileNames.contains(clientConfigFilename)
                {
                    var maybeReplicantConfig: ReplicantConfig?
                    
                    guard let clientConfig = ClientConfig(withConfigAtPath: configURL.appendingPathComponent(clientConfigFilename).path)
                        
                        else
                    {
                        appLog.error("Unable to create replicant config from file at \(configURL.appendingPathComponent(clientConfigFilename))")
                        
                        return nil
                    }
                    
                    // Replicant config from file
                    if fileNames.contains(replicantConfigFilename)
                    {
                        maybeReplicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(replicantConfigFilename).path)
                    }
                    else
                    {
                        maybeReplicantConfig = ReplicantConfig(serverIP: clientConfig.host, port: clientConfig.port, polish: nil, toneBurst: nil)
                    }
                    
                    let moonbounceConfig = MoonbounceConfig(name: configURL.lastPathComponent, clientConfig: clientConfig, replicantConfig: maybeReplicantConfig)
                    
                    
                    return moonbounceConfig
                }
            }
        }
        catch
        {
            return nil
        }
        
        return nil
    }
    
    public static func getMoonbounceConfig(fromProtocolConfiguration protocolConfiguration: NETunnelProviderProtocol) -> MoonbounceConfig?
    {
        var maybeReplicantConfig: ReplicantConfig?
        
        guard let providerConfiguration = protocolConfiguration.providerConfiguration else
        {
            appLog.error("\nAttempted to initialize a tunnel with a protocol config that does not have a provider config (no replicant or client configs).")
            return nil
        }
        
        // Client Config
        guard let clientConfigJSON = providerConfiguration[Keys.clientConfigKey.rawValue] as? Data else
        {
            appLog.error("Unable to get ClientConfig JSON from provider config")
            return nil
        }
        
        guard let clientConfig = ClientConfig.parse(jsonData: clientConfigJSON) else
        {
            return nil
        }
        
        // Replicant Config
        if let replicantJSON = providerConfiguration[Keys.replicantConfigKey.rawValue] as? Data
        {
            guard let replicantConfig = ReplicantConfig(from: replicantJSON) else
            {
                appLog.error("Unable to load the Replicant config data.")
                return nil
            }
            
            maybeReplicantConfig = replicantConfig
        }
        
        // Tunnel Name
        guard let name = providerConfiguration[Keys.tunnelNameKey.rawValue] as? String
        else
        {
            appLog.error("Unable to get tunnel name from provider config.")
            return nil
        }
        
        
        // Moonbounce Config
        let moonbounceConfig = MoonbounceConfig(name: name, clientConfig: clientConfig, replicantConfig: maybeReplicantConfig)
        
        return moonbounceConfig
    }
    
}


enum ConfigDirectory: String
{
    case importedDirectory = "Imported"
    case defaultDirectory = "Default"
}
