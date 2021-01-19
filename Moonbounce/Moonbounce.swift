//
//  Moonbounce.swift
//  Moonbounce
//
//  Created by Dr. Brandon Wiley on 9/14/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import Network

func checkForServerIP()
{
    let fileManager = FileManager.default

    // Try finding a user created server first
    let userConfigURL = userConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
    
    if let userConfig = ClientConfig(withConfigAtPath: userConfigURL.path)
    {
        userHost = NWEndpoint.Host(userConfig.host)
        return
    }
    
    // Next try finding the first available imported server
    if let importedDirectories = fileManager.subpaths(atPath: importedConfigDirectory.path),
        importedDirectories.count > 0,
        let importedClientConfig = ClientConfig(withConfigAtPath: importedConfigDirectory.appendingPathComponent(importedDirectories[0]).path)
    {
        userHost = NWEndpoint.Host(importedClientConfig.host)
        return
    }
    
    // If no user or imported servers exist use the default
    let defaultConfigURL = defaultConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
    
    if let defaultClientConfig = ClientConfig(withConfigAtPath: defaultConfigURL.path)
    {
        userHost = NWEndpoint.Host(defaultClientConfig.host)
        print("Default config pat: \(defaultConfigURL.path)")
        print("User host is \(defaultClientConfig.host)")
        print("Port: \(defaultClientConfig.port)")
        return
    }
    else
    {
        // TODO: Notify user when host information cannot be found
        appLog.error("\nUnable to find config directories at: \(defaultConfigURL)\n")
    }
}

func createServerConfigDirectories()
{
    let fileManager = FileManager.default
    
    // Imported config files directory - Configurations imported by the user via the file system
    // If the directory does not exist, this method creates it.
    do
    {
        try fileManager.createDirectory(at: importedConfigDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    catch let importedConfigDirError
    {
        appLog.error("\(importedConfigDirError)")
    }
    
    // User Config Directory - Configs created when the user launches a Digital Ocean server through our app
    // TODO: We may want to allow for and account for multiple user created servers
    do
    {
        try fileManager.createDirectory(at: userConfigDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    catch let userConfigDirError
    {
        appLog.error("\(userConfigDirError)")
    }
    
    // Default Config Directory
    do
    {
        try fileManager.createDirectory(at: defaultConfigDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    catch let defaultConfigDirError
    {
        appLog.error("\(defaultConfigDirError)")
    }
}
