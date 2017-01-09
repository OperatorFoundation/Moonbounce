//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

var helperClient:MoonbounceHelperProtocol?
let kOutputTextNotification: CFString = "OutputFromBashNotification" as CFString
let kConnectionStatusNotification = "ConnectionStatusChanged"
let kServerIPAvailableNotification = "PTServerIPAvailable"
var appDirectory = ""
var configFilesDirectory = ""
var terraformConfigDirectory = ""
var hasDoToken = false
var ptServerIP = ""
{
    didSet
    {
        if ptServerIP != ""
        {
            print("Changed Global var for server IP: \(ptServerIP)")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kServerIPAvailableNotification), object: ptServerIP)
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
