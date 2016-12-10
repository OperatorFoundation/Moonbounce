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
    /*Output Verbosity: Level 3 is recommended if you want a good summary of  what's
    happening without being swamped by output.
    
    0 -- No output except fatal errors.
    1 to 4 -- Normal usage range.
    5  -- Output R and W characters to the console for each packet read and write,
    uppercase is used for TCP/UDP packets and lowercase is used for TUN/TAP  pack-
    ets.
    6  to  11  --  Debug  info range (see errlevel.h for additional information on
    debug levels).*/
        

    public var configFileName = "config.ovpn"
//    public var outputPipe:Pipe?
    
    private var pathToOpenVPNExecutable:String
    private var pathToKext:String
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
        
        if let kextPath = Bundle.main.path(forResource: "tun-signed.kext", ofType: nil)
        {
            pathToKext = kextPath
        }
        else
        {
            print("Could not find our kext!")
            pathToKext = ""
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
            helperClient!.startOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, kextFilePath: pathToKext, configFileName: configFileName)
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
            helperClient!.stopOpenVPN(kextFilePath: pathToKext)
            completion(true)
        }
        else
        {
            completion(false)
        }
    }
    

/*🌙*/
}
