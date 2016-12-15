//
//  OpenVPN.swift
//  Moonbounce
//
//  Created by Adelita Schule on 11/7/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

//public let kOutputTextNotification = "OutputFromBashNotification"
//public let outputStringKey = "outputString"

public class OpenVPN: NSObject
{
    public var configFileName = "config.ovpn"
    
    private var pathToOpenVPNExecutable:String
    private var directory:String = ""
    
    public override init()
    {
        if let openVpnPath = Bundle.main.path(forResource: "openvpn", ofType: nil)
        {
            pathToOpenVPNExecutable = openVpnPath
        }
        else
        {
            print("Could not find openVPN executable. wtf D:")
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
    
    public func start(completion:@escaping (_ launched:Bool) -> Void)
    {
        if helperClient != nil
        {
            helperClient!.startOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, configFileName: configFileName)
            completion(true)
        }
        else
        {
             completion(false)
        }
    }
    
    public func stop(completion:(_ stopped:Bool) -> Void)
    {
        if helperClient != nil
        {
            helperClient!.stopOpenVPN()
            completion(true)
        }
        else
        {
            completion(false)
        }
    }
    

/*🌙*/
}
