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

class  ConfigController
{
    let fileManager = FileManager.default
    let configsDirectory: URL
    
    var configs = [MoonbounceConfig]()
    
    init?()
    {
        guard let configsURL = ConfigController.getMainConfigDirectory()
            else
        {
            return nil
        }
        
        self.configsDirectory = configsURL
    }
    
    func getDefaultMoonbounceConfig()-> MoonbounceConfig?
    {
        let fileManager = FileManager.default
        guard let configController = ConfigController()
        else
        {
            print("Unable to create default config: Config controller was not initialized correctly.")
            return nil
        }

        guard let dDirectory = configController.get(configDirectory: .defaultDirectory)
        else
        {
            print("Unable to get default directory.")
            return nil
        }


        if fileManager.fileExists(atPath: dDirectory.path)
        {
            do
            {
                try fileManager.removeItem(at: dDirectory)
            }
            catch let error
            {
                print("Error deleting files in default directory: \(error)")
            }
        }

        guard let moonbounceZip = Bundle.main.url(forResource: "default.moonbounce", withExtension: nil)
        else
         {
            print("\nUnable to find the default config file in the bundle")
            return nil
        }

        do
        {
            try fileManager.unzipItem(at: moonbounceZip, to: dDirectory, progress: nil)
            
            // Print for debug use only
            do
            {
                 let files = try fileManager.contentsOfDirectory(atPath: dDirectory.path)
                print(files)
            }
            catch let error
            {
                print("error listing contents of default directory: \(error)")
            }

            if let moonbounceConfig = createMoonbounceConfigFromFiles(atURL: dDirectory)
            {
                return moonbounceConfig
            }
        }
        catch let error
        {
            print("Error unzipping item: \(error)")
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
            print("Unable to get the config directory")
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
                    print("Error unzipping item: \(error)")
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
            print("\nError deleting config at \(url): \(error)\n")
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
                
                print("File enumerator error at \(configURL.path): \(error.localizedDescription)")
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
                        print("Unable to create replicant config from file at \(configURL.appendingPathComponent(file1))")
                        
                        return false
                    }
                    
                    // FIXME: Replicant Config from JSON
                    //let replicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(file1).path)
                    
                    let moonbounceConfig = MoonbounceConfig(name: configURL.lastPathComponent, clientConfig: clientConfig, replicantConfig: nil)
                    
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
    
    static func documentsDirectoryURL() -> URL?
    {
        if let docDirectory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            return docDirectory
        }
        else
        {
            return nil
        }
    }
    
    static func getMainConfigDirectory() -> URL?
    {
        
        guard let appDocumentsDirectory = documentsDirectoryURL()
        else
        {
            return nil
        }
        
        let configsURL = appDocumentsDirectory.appendingPathComponent("Configs")
        
        return configsURL
    }
    
    func get(configDirectory: ConfigDirectory) -> URL?
    {
        let thisDirectory = configsDirectory.appendingPathComponent(configDirectory.rawValue)
        
        do
        {
            try fileManager.createDirectory(at: thisDirectory, withIntermediateDirectories: true, attributes: nil)
            return thisDirectory
        }
        catch let error
        {
            print("Error creating \(configDirectory.rawValue): \(error)")
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
                    
                    print("File enumerator error at \(configURL.path): \(error.localizedDescription)")
                    return true
            })
            {
                //Verify  that each of the following files are present as all config files are neccessary for successful connection:
                let file1 = "replicantclient.config"
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
                if fileNames.contains(file1)
                {
                    guard let clientConfig = ClientConfig(withConfigAtPath: configURL.appendingPathComponent(file1).path)
                        
                        else
                    {
                        print("Unable to create replicant config from file at \(configURL.appendingPathComponent(file1))")
                        
                        return nil
                    }
                    
                    // FIXME: Replicant config from JSON
                    
//                    let replicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(file2).path)
                    
                    let moonbounceConfig = MoonbounceConfig(name: configURL.lastPathComponent, clientConfig: clientConfig, replicantConfig: nil)
                    
                    
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
        guard let providerConfiguration = protocolConfiguration.providerConfiguration
            else
        {
            print("\nAttempted to initialize a tunnel with a protocol config that does not have a provider config (no replicant or client configs).")
            return nil
        }
        
        // FIXME: Replicant config from JSON
        
//        guard let replicantConfigJSON = providerConfiguration[Keys.replicantConfigKey.rawValue] as? Data
//            else
//        {
//            print("Unable to get ReplicantConfig JSON from provider config")
//            return nil
//        }
//
//        guard let replicantConfig = ReplicantConfig.parse(jsonData: replicantConfigJSON)
//            else
//        {
//            return nil
//        }
        
        guard let replicantConfig = ReplicantConfig(polish: nil, toneBurst: nil)
            else
        {
            return nil
        }
        
        guard let clientConfigJSON = providerConfiguration[Keys.clientConfigKey.rawValue] as? Data
            else
        {
            print("Unable to get ClientConfig JSON from provider config")
            return nil
        }
        
        guard let clientConfig = ClientConfig.parse(jsonData: clientConfigJSON)
            else
        {
            return nil
        }
        
        guard let name = providerConfiguration[Keys.tunnelNameKey.rawValue] as? String
        else
        {
            print("Unable to get tunnel name from provider config.")
            return nil
        }
        
        let moonbounceConfig = MoonbounceConfig(name: name, clientConfig: clientConfig, replicantConfig: replicantConfig)
        
        return moonbounceConfig
    }
    
}


enum ConfigDirectory: String
{
    case importedDirectory = "Imported"
    case defaultDirectory = "Default"
}
