//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import Logging
import Net

public var appLog = Logger(label: "Moonbounce.MacOS.AppLogger")

public let mbDarkBlue = NSColor(red:0.00, green:0.06, blue:0.16, alpha:1.0)
public let mbWhite = NSColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)

public let kConnectionStatusNotification = "ConnectionStatusChanged"
//public let userDirectoryName = "User"
//public let importedDirectoryName = "Imported"
//public let defaultDirectoryName = "Default"
public let defaultTunnelName = "Default"
//public let moonbounceExtension = "moonbounce"

//let serverManager = ServerController(completionHandler: {NotificationCenter.default.post(Notification(name: Notification.Name(serverManagerReadyNotification)))})

//public var moonbounceDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Moonbounce.macOS", isDirectory: true)

// Parent config files directory - One directory to rule them all
//public let configFilesDirectory = moonbounceDirectory.appendingPathComponent("ConfigFiles", isDirectory: true)

//Default Config file directory - This is the config we supply for the demo server we run
//public let defaultConfigDirectory = configFilesDirectory.appendingPathComponent(defaultDirectoryName
//   , isDirectory: true)

// Imported config files directory - Configurations imported by the user via the file system
// public var importedConfigDirectory = configFilesDirectory.appendingPathComponent(importedDirectoryName, isDirectory: true)

// User Config Directory - Created when the user launches a Digital Ocean server through our app
// public var userConfigDirectory = configFilesDirectory.appendingPathComponent(userDirectoryName + "/DO", isDirectory: true)

//var currentConfigDirectory = defaultConfigDirectory

//public var currentHost: String?
//public var userHost: String?
//{
//    didSet
//    {
//        if userHost != nil
//        {
//            appLog.debug("Changed Global var for server IP: \(userHost!)")
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kServerIPAvailableNotification), object: userHost!)
//        }
//    }
//}

public var isConnected = State.start
{
    didSet
    {
        print("☾ Global isConnected var updated: \(isConnected)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kConnectionStatusNotification), object: isConnected)
    }
}

//public struct ConnectState
//{
//    var state: State = .start
//    var stage: Stage = .start
//    
//    public init(state: State, stage: Stage)
//    {
//        self.state = state
//        self.stage = stage
//    }
//}

public enum State
{
    case start
    case trying
    case success
    case failed
}
//
//public enum Stage
//{
//    case start
//    case dispatcher
//    case management
//    case statusCodes
//}
