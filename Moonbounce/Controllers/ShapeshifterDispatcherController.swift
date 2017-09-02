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
            print("👀 LaunchShapeShifterDispatcher Args:\n \(arguments) 👀")
            
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
            launchTask!.launch()
        }
        else
        {
            print("Could not create/find the transport state directory path, which is required.")
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
        if let stateDirectory = createTransportStateDirectory(), let obfs4Options = getObfs4Options()
        {
            //List of arguments for Process/Task
            var processArguments: [String] = []
            
            //TransparentTCP is our proxy mode.
            processArguments.append("-transparent")
            
            //Puts Dispatcher in client mode.
            processArguments.append("-client")

            //IP and Port for our PT Server
            processArguments.append("-target")
            processArguments.append("\(currentServerIP):\(ptServerPort)")
            
            //Here is our list of transports (more than one would launch multiple proxies)
            processArguments.append("-transports")
            processArguments.append("obfs4")
            
            /// -bindaddr string
            //Specify the bind address for transparent server
            processArguments.append("-bindaddr")
            processArguments.append("obfs4-127.0.0.1:1234")
            
            //Paramaters needed by the specific transport being used (obfs4)
            processArguments.append("-options")
            processArguments.append(obfs4Options)
            
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
    
    func getObfs4Options() -> String?
    {
        //Get the file that has the current servers obfs4 options
        if currentConfigDirectory != ""
        {
            let optionsPath = currentConfigDirectory.appending("/" + obfs4OptionsFileName)
            
            do
            {
                let obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: optionsPath, isDirectory: false), options: .uncached)
                if let untrimmedOptions = String(data: obfs4OptionsData, encoding: String.Encoding.ascii)
                {
                    let obfs4Options = untrimmedOptions.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("✅ Found obfs4 options.")
                    return obfs4Options
                }
                else
                {
                    return nil
                }
                
            }
            catch
            {
                print("⁉️ Unable to locate the needed obfs4 options ⁉️.")
                return nil
            }
        }
        else
        {
            print("⁉️ We do not know which config directory to look at in order to get our obfs4 details ⁉️")
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
                    print(theError)
                }
                
                //Application Queue Directory
                let stateDirectoryPath = directoryPath.appendingPathComponent("TransportState", isDirectory: true)
                
                do
                {
                    try fileManager.createDirectory(at: stateDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let queueDirError
                {
                    print(queueDirError)
                }
                
                return stateDirectoryPath.path
            }
        }
        
        return nil
    }
}
