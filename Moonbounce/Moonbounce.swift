//
//  Moonbounce.swift
//  Moonbounce
//
//  Created by Dr. Brandon Wiley on 9/14/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation

func checkForServerIP()
{
    let fileManager = FileManager.default

    // Try finding a user created server first
    let userConfigURL = userConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
    
    if let userConfig = ClientConfig(withConfigAtPath: userConfigURL.path)
    {
        userHost = userConfig.host
        return
    }
    
    // Next try finding the first available imported server
    if let importedDirectories = fileManager.subpaths(atPath: importedConfigDirectory.path),
        importedDirectories.count > 0,
        let importedClientConfig = ClientConfig(withConfigAtPath: importedDirectories[0])
    {
        userHost = importedClientConfig.host
        return
    }
    
    // If no user or imported servers exist use the default
    let defaultConfigURL = defaultConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
    
    if let defaultClientConfig = ClientConfig(withConfigAtPath: defaultConfigURL.path)
    {
        userHost = defaultClientConfig.host
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
    catch let importedConfigError
    {
        appLog.error("\(importedConfigError)")
    }
    
    // User Config Directory - Created when the user launches a Digital Ocean server through our app
    // TODO: We may want to allow for and account for multiple user created servers
    do
    {
        try fileManager.createDirectory(at: userConfigDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    catch let userConfigError
    {
        appLog.error("\(userConfigError)")
    }
}
