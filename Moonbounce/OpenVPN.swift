//
//  OpenVPN.swift
//  Moonbounce
//
//  Created by Adelita Schule on 11/7/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import SwiftSocket

//public let kOutputTextNotification = "OutputFromBashNotification"
//public let outputStringKey = "outputString"

public class OpenVPN: NSObject
{
    public var configFileName = "DO.ovpn"
    
    private var pathToOpenVPNExecutable:String
    private var directory:String = ""
    let client = TCPClient(address: "127.0.0.1", port: 13374)
    
    public override init()
    {
        isConnected = ConnectState(state: .trying, stage: .openVpn)
        
        if let openVpnPath = Bundle.main.path(forResource: "openvpn", ofType: nil)
        {
            pathToOpenVPNExecutable = openVpnPath
        }
        else
        {
            print("Could not find openVPN executable. wtf D:")
            isConnected = ConnectState(state: .failed, stage: .openVpn)
            pathToOpenVPNExecutable = ""
        }

        super.init()
        
        if let pathToConfig = getApplicationDirectory()
        {
            directory = pathToConfig.path
        }
        
        //Add listener for app termination so that openVPN connection can be killed
        NotificationCenter.default.addObserver(forName: Notification.Name.NSApplicationWillTerminate, object: nil, queue: nil, using:
        {
            notification in
            self.stop(completion:
            {
                (connectionStopped) in
                
                if connectionStopped == false
                {
                    print("Attempted to kill OpenVPN process on program exit and failed.")
                }
                else
                {
                    print("Killed OpenVPN process for program exit.")
                }
            })
        })
    }
    
    public func start(completion:@escaping (_ launched:Bool) -> Void)
    {
        if let helper = helperClient
        {
            helper.startOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, configFilePath: directory, configFileName: configFileName)
                        
            isConnected = ConnectState(state: .success, stage: .openVpn)
            connectToManagement()
            completion(true)
        }
        else
        {
             completion(false)
            isConnected = ConnectState(state: .failed, stage: .openVpn)
        }
    }
    
    public func stop(completion:(_ stopped:Bool) -> Void)
    {
        if let helper = helperClient
        {
            helper.stopOpenVPN()
            completion(true)
        }
        else
        {
            completion(false)
        }
        
        disconnectFromManagement()
        isConnected.stage = .start
        isConnected.state = .start
    }
    
    func getApplicationDirectory() -> (URL)?
    {
        if let bundleID: String = Bundle.main.bundleIdentifier
        {
            let fileManager = FileManager.default
            
            // Find the application support directory in the home directory.
            let appSupportDirectory = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
            if appSupportDirectory.count > 0
            {
                // Append the bundle ID to the URL for the
                // Application Support directory
                let directoryPath = appSupportDirectory[0].appendingPathComponent(bundleID)
                
                // If the directory does not exist, this method creates it.
                // This method is only available in OS X v10.7 and iOS 5.0 or later.
                
                do
                {
                    try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let theError
                {
                    // Handle the error.
                    print(theError)
                    return nil;
                }
                
                return directoryPath
            }
        }
        
        return nil
    }
    
    func connectToManagement()
    {
        isConnected = ConnectState(state: .trying, stage: .management)
        
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async
        {
            var connectedToManagment = false
            
            while !connectedToManagment
            {
                switch self.client.connect(timeout: 10)
                {
                    case .success:
                        print("Connected to management server! 🌈")
                        connectedToManagment = true
                    case .failure(let connectError):
                        print("Failed to connect to management server. 🥀")
                        print("Connection failure: \(connectError)")
                }
                
                sleep(1)
            }
            
            let requestString = "state\nstate on\n"
            
            if let requestData = requestString.data(using: .utf8)
            {
                switch self.client.send(data: requestData)
                {
                    case .success:
                        isConnected = ConnectState(state: .success, stage: .management)
                    case .failure(let requestError):
                        isConnected = ConnectState(state: .failed, stage: .management)
                        print("Management Request Failed: \(requestError)")
                        return
                }
                
                var responseString = ""
                while true
                {
                    if let data = self.client.read(4096)
                    {
                        responseString.append(String(bytes: data, encoding: .ascii)!)
                        
                        while responseString.contains("\r\n")
                        {
                            let arrayOfLines = responseString.components(separatedBy: "\r\n")
                            var firstLine = arrayOfLines[0]
                            firstLine.append("\r\n")
                            if let range = responseString.range(of: firstLine)
                            {
                                responseString.removeSubrange(range)
                            }
                            print("FirstLine: \(firstLine)")
                            print("responseString: \(responseString)")
                            
                            if firstLine .contains(",")
                            {
                                let arrayOfComponents = firstLine.components(separatedBy: ",")
                                let statusString = arrayOfComponents[1]
                                print("Status: \(statusString)")
                                isConnected.stage = .statusCodes
                                
                                switch statusString
                                {
                                    case "CONNECTED", "TCP_CONNECT":
                                        //Woohoo we connected, update the UI or some shit
                                        isConnected.state = .success
                                    case "RECONNECTING", "WAIT", "RECONNECTING":
                                        isConnected.state = .trying
                                    case "EXITING":
                                        //Closed OpenVPN Connection
                                        isConnected.state = .start
                                        isConnected.stage = .start
                                    default:
                                        print("\nError: Unknown connection status: \(statusString)\n")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func disconnectFromManagement()
    {
        client.close()
    }
    
    
/*🌙*/
}

