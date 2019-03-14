//
//  configController.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 1/18/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
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
                    
                    let replicantConfig = ReplicantConfig(withConfigAtPath: configURL.appendingPathComponent(file1).path)
                    
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
    
}


enum ConfigDirectory: String
{
    case importedDirectory = "Imported"
    case defaultDirectory = "Default"
}
