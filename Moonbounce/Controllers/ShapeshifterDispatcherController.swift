//
//  ShapeshifterDispatcherController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/21/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class ShapeshifterDispatcherController: NSObject
{
    private var launchTask: Process?
    let ptServerPort = "1234"
    static let sharedInstance = ShapeshifterDispatcherController()
    
    func launchShapeshifterDispatcherClient()
    {
        if let arguments = shapeShifterDispatcherArguments()
        {
            appLog.debug("👀 LaunchShapeShifterDispatcher Args:\n \(arguments) 👀")
            
            if launchTask == nil
            {
                //Creates a new Process and assigns it to the launchTask property.
                launchTask = Process()
            }
            else
            {
                launchTask!.terminate()
                launchTask = Process()
            }
            
            //The launchPath is the path to the executable to run.
            launchTask!.launchPath = Bundle.main.path(forResource: "shapeshifter-dispatcher", ofType: nil)
            launchTask!.arguments = arguments
            
            do
            {
                try launchTask!.run()
            }
            catch let runError
            {
                appLog.error("Failed to launch dispatcher: \(runError)")
                return
            }
        }
        else
        {
            appLog.error("Could not create/find the transport state directory path, which is required.")
        }
    }
    
    func stopShapeshifterDispatcherClient()
    {
        if launchTask != nil
        {
            launchTask?.terminate()
            launchTask = nil
        }
    }
    
    func shapeShifterDispatcherArguments() -> [String]?
    {
        if let stateDirectory = createTransportStateDirectory(), let currentIP = currentHost
        {
            //List of arguments for Process/Task
            var processArguments: [String] = []
            
            //TransparentTCP is our proxy mode.
            processArguments.append("-transparent")
            
            //Puts Dispatcher in client mode.
            processArguments.append("-client")

            //IP and Port for our PT Server
            processArguments.append("-target")
            processArguments.append("\(currentIP):\(ptServerPort)")
            
            //Here is our list of transports (more than one would launch multiple proxies)
            processArguments.append("-transports")
            processArguments.append("replicant")
            
//            /// -bindaddr string
//            //Specify the bind address for transparent server
//            processArguments.append("-bindaddr")
//            processArguments.append("obfs4-127.0.0.1:1234")
//
//            //Paramaters needed by the specific transport being used (obfs4)
//            processArguments.append("-options")
//            processArguments.append(obfs4Options)
            
            //Creates a directory if it doesn't already exist for transports to save needed files
            processArguments.append("-state")
            processArguments.append(stateDirectory)
            
            /// -logLevel string
            //Log level (ERROR/WARN/INFO/DEBUG) (default "ERROR")
            processArguments.append("-logLevel")
            processArguments.append("DEBUG")
            
            //Log to TOR_PT_STATE_LOCATION/dispatcher.log
            processArguments.append("-enableLogging")
            
            /// -ptversion string
            //Specify the Pluggable Transport protocol version to use
            //We are using Pluggable Transports version 2.0
            processArguments.append("-ptversion")
            processArguments.append("2")

            //TODO Listen on a port for OpenVPN Client
            
            return processArguments
        }
        else
        {
            return nil
        }
    }
    
    func createTransportStateDirectory() ->String?
    {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        if appSupportDirectory.count > 0
        {
            if let bundleID: String = Bundle.main.bundleIdentifier
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
                    appLog.error("\(theError)")
                }
                
                //Application Queue Directory
                let stateDirectoryPath = directoryPath.appendingPathComponent("TransportState", isDirectory: true)
                
                do
                {
                    try fileManager.createDirectory(at: stateDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let queueDirError
                {
                    appLog.error("\(queueDirError)")
                }
                
                return stateDirectoryPath.path
            }
        }
        
        return nil
    }
}
