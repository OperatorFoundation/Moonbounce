//
//  OpenVPN.swift
//  Moonbounce
//
//  Created by Adelita Schule on 11/7/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

public let kOutputTextNotification = "OutputFromBashNotification"
public let outputStringKey = "outputString"

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
    public var outputPipe:Pipe?
    
    private var pathToOpenVPNExecutable:String
    private var directory:String = ""
    
    public init(pathToOVPNExecutable: String)
    {
        self.pathToOpenVPNExecutable = pathToOVPNExecutable
        
        super.init()
        
        ///Blah blah make or get Application Support Directory
        if let directoryURL = getApplicationDirectory()
        {
            self.directory = directoryURL.path
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
    
    public func start(completion:@escaping (_ launched:Bool) -> Void)
    {
        
        //Path to script file
        guard let path = Bundle.main.path(forResource: "openvpn", ofType: nil)
            else
        {
            print("Unable to locate openVPN program")
            return
        }
//        
//        //Arguments
//        let arguments = connectToOpenVPNArguments()
//        
//        runScript(path, arguments: arguments)
//        { (wasLaunched) in
//            completion(wasLaunched)
//        }
    }
    
    public func stop(completion:(_ stopped:Bool) -> Void)
    {

    }
    

/*🌙*/
}
