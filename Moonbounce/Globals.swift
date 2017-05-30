//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

let mbPink = NSColor(red:0.92, green:0.55, blue:0.73, alpha:1.0)
let mbDarkBlue = NSColor(red:0.00, green:0.06, blue:0.16, alpha:1.0)
let mbBlue = NSColor(red:0.16, green:0.20, blue:0.48, alpha:1.0)
let mbWhite = NSColor(red:0.97, green:0.97, blue:0.98, alpha:1.0)

var helperClient:MoonbounceHelperProtocol?
let kConnectionStatusNotification = "ConnectionStatusChanged"
let kServerIPAvailableNotification = "PTServerIPAvailable"
let userTokenKey = "UserDoToken"
let userDirectoryName = "User"
let importedDirectoryName = "Imported"
let defaultDirectoryName = "Default"
let ipFileName = "serverIP"
let obfs4OptionsFileName = "obfs4.json"


var appDirectory = ""
var configFilesDirectory = ""

var defaultConfigDirectory = ""
var importedConfigDirectory = ""
var userConfigDirectory = ""
var currentConfigDirectory = ""
var currentServerIP = ""
var userServerIP = ""
{
    didSet
    {
        if userServerIP != ""
        {
            print("Changed Global var for server IP: \(userServerIP)")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kServerIPAvailableNotification), object: userServerIP)
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
