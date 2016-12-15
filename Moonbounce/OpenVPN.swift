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
    public var configFileName = "DO.ovpn"
    
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
        print("About to call startOpenVPN")
        if let helper = helperClient
        {
            helper.testLog()
            helper.test(callback:
            {
                (responseString) in
                
                print(responseString)
            })
            
            helper.testStartOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, configFilePath: directory, configFileName: configFileName)
            
            helper.startOpenVPN(openVPNFilePath: pathToOpenVPNExecutable, configFilePath: directory, configFileName: configFileName)
                        
            print("startOpenVPN was called.")
            
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
    

/*🌙*/
}
