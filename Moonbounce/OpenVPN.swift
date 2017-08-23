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
    
    public func start(configFilePath: String, completion:@escaping (_ launched:Bool) -> Void)
    {
        if let helper = helperClient
        {
            helper.startOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, configFilePath: configFilePath, configFileName: configFileName)
            
            print("Config File Path: \(configFilePath)")
            print("Config File Name: \(configFileName)")
                        
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
    
    func connectToManagement()
    {
        isConnected = ConnectState(state: .trying, stage: .management)
        
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async
        {
            var connectedToManagment = false
            var failureCount = 0
            
            while !connectedToManagment && failureCount < 20 && isConnected.state == .trying && isConnected.stage == .management
            {
                switch self.client.connect(timeout: 10)
                {
                    case .success:
                        print("Connected to management server! 🌈")
                        connectedToManagment = true
                    case .failure(let connectError):
                        print("Failed to connect to management server. 🥀")
                        failureCount += 1
                        print("Connection failure: \(connectError)\nFailures: \(failureCount)")
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
                                        //Woohoo we connected, update the UI
                                        isConnected.state = .success
                                    case "RECONNECTING", "WAIT", "RECONNECTING":
                                        isConnected.state = .trying
                                    case "EXITING":
                                        //Closed OpenVPN Connection
                                        isConnected.state = .start
                                        isConnected.stage = .start
                                    default:
                                        continue
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

