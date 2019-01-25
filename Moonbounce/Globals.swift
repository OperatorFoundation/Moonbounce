//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import Network

let mbPink = NSColor(red:0.92, green:0.55, blue:0.73, alpha:1.0)
let mbDarkBlue = NSColor(red:0.00, green:0.06, blue:0.16, alpha:1.0)
let mbBlue = NSColor(red:0.16, green:0.20, blue:0.48, alpha:1.0)
let mbWhite = NSColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)

let kConnectionStatusNotification = "ConnectionStatusChanged"
let kServerIPAvailableNotification = "PTServerIPAvailable"
let kNewServerAddedNotification = "NewServerHasBeenAdded"
let userTokenKey = "UserDoToken"
let userDirectoryName = "User"
let importedDirectoryName = "Imported"
let defaultDirectoryName = "Default"
let clientConfigFileName = "replicantclient.config"
let replicantConfigFileName = "replicant.config"
let moonbounceExtension = "moonbounce"

let serverManager = ServerController()
let appSupportDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)

var moonbounceDirectory = appSupportDirectory[0].appendingPathComponent("Moonbounce.macOS", isDirectory: true)

// Parent config files directory - One directory to rule them all
let configFilesDirectory = moonbounceDirectory.appendingPathComponent("ConfigFiles", isDirectory: true)

//Default Config file directory - This is the config we supply for the demo server we run
let defaultConfigDirectory = configFilesDirectory.appendingPathComponent(defaultDirectoryName
    , isDirectory: true)

// Imported config files directory - Configurations imported by the user via the file system
var importedConfigDirectory = configFilesDirectory.appendingPathComponent(importedDirectoryName, isDirectory: true)

// User Config Directory - Created when the user launches a Digital Ocean server through our app
var userConfigDirectory = configFilesDirectory.appendingPathComponent(userDirectoryName + "/DO", isDirectory: true)

//var currentConfigDirectory = defaultConfigDirectory

var currentHost: NWEndpoint.Host?
var userHost: NWEndpoint.Host?
{
    didSet
    {
        if userHost != nil
        {
            print("Changed Global var for server IP: \(userHost!)")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kServerIPAvailableNotification), object: userHost!)
        }
    }
}

var isConnected = ConnectState(state: .start, stage: .start)
{
    didSet
    {
        print("Changed Global var for connection status: \(isConnected)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kConnectionStatusNotification), object: isConnected)
    }
}

struct ConnectState
{
    var state: State = .start
    var stage: Stage = .start
    
    init(state: State, stage: Stage)
    {
        self.state = state
        self.stage = stage
    }
}

enum State
{
    case start
    case trying
    case success
    case failed
}

enum Stage
{
    case start
    case dispatcher
    case openVpn
    case management
    case statusCodes
}
