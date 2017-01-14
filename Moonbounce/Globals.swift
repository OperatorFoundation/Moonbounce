//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

var helperClient:MoonbounceHelperProtocol?
let kConnectionStatusNotification = "ConnectionStatusChanged"
let kServerIPAvailableNotification = "PTServerIPAvailable"
let userTokenKey = "UserDoToken"
let userDirectoryName = "User"
let importedDirectoryName = "Imported"
let defaultDirectoryName = "Default"
let ipFileName = "serverIP"
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
