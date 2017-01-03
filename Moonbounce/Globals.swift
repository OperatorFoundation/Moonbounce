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
let kConnectionStatusNotification = "ConnectionStatusChnaged"
var ptServerIP = ""
var appDirectory = ""
var configFilesDirectory = ""
var terraformConfigDirectory = ""
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

//func getApplicationDirectory() -> (URL)?
//{
//    if let bundleID: String = Bundle.main.bundleIdentifier
//    {
//        let fileManager = FileManager.default
//        
//        // Find the application support directory in the home directory.
//        let appSupportDirectory = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
//        if appSupportDirectory.count > 0
//        {
//            // Append the bundle ID to the URL for the
//            // Application Support directory
//            let directoryPath = appSupportDirectory[0].appendingPathComponent(bundleID)
//            
//            // If the directory does not exist, this method creates it.
//            // This method is only available in OS X v10.7 and iOS 5.0 or later.
//            
//            do
//            {
//                try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
//            }
//            catch let theError
//            {
//                // Handle the error.
//                print(theError)
//                return nil;
//            }
//            
//            return directoryPath
//        }
//    }
//    
//    return nil
//}
