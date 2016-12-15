//
//  MoonbounceHelper.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

class MoonbounceHelper: NSObject, MoonbounceHelperProtocol, NSXPCListenerDelegate
{
    static var connectTask:Process!
    var verbosity = 3
    
    let logPath = NSHomeDirectory()+"/Documents/debug.log"
    
    fileprivate var listener:NSXPCListener
    fileprivate let kHelperToolMachServiceName = "org.OperatorFoundation.MoonbounceHelperTool"
    
    override init()
    {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = NSXPCListener(machServiceName:kHelperToolMachServiceName)
        super.init()
        self.listener.delegate = self
        self.writeToLog(content: "Initialized Helper Tool")
    }
    
    func run()
    {
        // Tell the XPC listener to start processing requests.
        
        // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
        self.listener.resume()
        
        //TODO: TESTING ONLY
        self.startOpenVPN(openVPNFilePath: "/Users/Lita/Library/Developer/Xcode/DerivedData/Moonbounce-aosqeamddmsgekczgdbfntvzubaw/Build/Products/Debug/Moonbounce.app/Contents/Resources/openvpn", configFileName: "config.ovpn")
        
        // Run the run loop forever.
        RunLoop.current.run()
    }
    
    // Called by our XPC listener when a new connection comes in.  We configure the connection
    // with our protocol and ourselves as the main object.
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool
    {
        print("new incoming connection")
        // Configure the new connection and resume it. Because this is a singleton object, we set 'self' as the exported object and configure the connection to export the 'SMJobBlessHelperProtocol' protocol that we implement on this object.
        newConnection.exportedInterface = NSXPCInterface(with:MoonbounceHelperProtocol.self)
        newConnection.exportedObject = self;
        newConnection.resume()
        return true
    }
    
    func startOpenVPN(openVPNFilePath: String, configFileName: String)
    {
        //Arguments
        ///Blah blah make or get Application Support Directory
        guard let appDirectory = getApplicationDirectory()?.path
            else
        {
            print("Unable to locate application directory.")
            return
        }
        
        let openVpnArguments = connectToOpenVPNArguments(directory: appDirectory, configFileName: configFileName)
        
        _ = runOpenVpnScript(openVPNFilePath, arguments: openVpnArguments)
    }
    
    func stopOpenVPN()
    {
        //Disconnect OpenVPN
        if MoonbounceHelper.connectTask != nil
        {
            MoonbounceHelper.connectTask!.terminate()
        }
        
        //TODO: Notify main app of success or failure
    }
    
    private func connectToOpenVPNArguments(directory: String, configFileName: String) -> [String]
    {
        //List of arguments for Process/Task
        var processArguments: [String] = []
        
        
        //processArguments.append("--daemon")
        processArguments.append("--cd")
        processArguments.append(directory)
        processArguments.append("--verb")
        processArguments.append(String(verbosity))
        processArguments.append("--config")
        processArguments.append(configFileName)
        processArguments.append("--verb")
        processArguments.append(String(verbosity))
        processArguments.append("--cd")
        processArguments.append(directory)
        processArguments.append("--log")
        processArguments.append("/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/openVPNLog.txt")
//        processArguments.append("--management")
//        processArguments.append("127.0.0.1")
//        processArguments.append("1337")
//        processArguments.append("--management-query-passwords")
        //processArguments.append("--management-hold")
        
        return processArguments
    }
    
    private func runOpenVpnScript(_ path: String, arguments: [String]) -> Bool
    {
        writeToLog(content: "Helper func: runOpenVpnScript")
        //Run heavy lifting on the background thread.
        //let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        //taskQueue.async
            //{
                //Creates a new Process and assigns it to the connectTask property.
                MoonbounceHelper.connectTask = Process()
                //The launchPath is the path to the executable to run.
                MoonbounceHelper.connectTask.launchPath = path
                //Arguments will pass the arguments to the executable, as though typed directly into terminal.
                MoonbounceHelper.connectTask.arguments = arguments
                print(arguments)
                
                let outputPipe = Pipe()
                MoonbounceHelper.connectTask.standardOutput = outputPipe
                let errorPipe = Pipe()
                MoonbounceHelper.connectTask.standardError = errorPipe
                
                //self.addOutputObserver(process: MoonbounceHelper.connectTask, outputPipe: Pipe())
                
                //Go ahead and launch the process/task
                MoonbounceHelper.connectTask.launch()
                
                let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let outString = String(data: outData, encoding: .utf8)
                {
                    print(outString)
                    self.writeToLog(content: outString)
                }
                
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let errorString = String(data: errorData, encoding: .utf8)
                {
                    if errorString != ""
                    {
                        print(errorString)
                        self.writeToLog(content: "Error: \(errorString)")
                    }
                }
                
                MoonbounceHelper.connectTask.waitUntilExit()
                
                let status = MoonbounceHelper.connectTask.terminationStatus
                self.writeToLog(content: "Termination Status: \(status)")
        //}
        
        //This may be a lie :(
        return true
    }
    
/*    func loadKextScript(arguments: [String])
    {
        print("Helper func: loadKextScript")
        //Creates a new Process and assigns it to the connectTask property.
        let kextTask = Process()
        
        //The launchPath is the path to the executable to run.
        kextTask.launchPath = "/sbin/kextload"
        
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        kextTask.arguments = arguments
        
        self.addOutputObserver(process: kextTask, outputPipe: Pipe())
        kextTask.launch()
        
        //Block any other activity on this thread until the process/task is finished
        kextTask.waitUntilExit()
        
        if !kextTask.isRunning
        {
            let status = kextTask.terminationStatus
            
            //TODO: You’ll need to look at the documentation for that task to learn what values it returns under what circumstances.
            if status == 0
            {
                print("Connect Task status == 0.")
            }
            else
            {
                print("Connect Task Status == \(status.description).")
            }
        }
    }
 
    
    func unloadKextScript(arguments: [String])
    {
        //Creates a new Process and assigns it to the connectTask property.
        let kextUnloadTask = Process()
        
        //The launchPath is the path to the executable to run.
        kextUnloadTask.launchPath = "/sbin/kextunload"
        
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        kextUnloadTask.arguments = arguments
        
        self.addOutputObserver(process: kextUnloadTask, outputPipe: Pipe())
        kextUnloadTask.launch()
        
        //Block any other activity on this thread until the process/task is finished
        kextUnloadTask.waitUntilExit()
        
        if !kextUnloadTask.isRunning
        {
            let status = kextUnloadTask.terminationStatus
            
            //TODO: You’ll need to look at the documentation for that task to learn what values it returns under what circumstances.
            if status == 0
            {
                print("Connect Task status == 0.")
            }
            else
            {
                print("Connect Task Status == \(status.description).")
            }
        }
    }
 */
    
    //Dev purposes - Show output from command line task
    func addOutputObserver(process: Process, outputPipe: Pipe)
    {
        process.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil, using:
        {
            notification in
            
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            //TODO: Save output to a log file
            print(outputString)
            self.writeToLog(content: outputString)
            CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFNotificationName(rawValue: kOutputTextNotification), outputString, nil, true)
            
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })
    }
    
    func writeToLog(content: String)
    {
        let timeStamp = Date()
        let contentString = "\n\(timeStamp):\n\(content)\n"
        if let path = self.getApplicationDirectory()?.appendingPathComponent("moonbounceLog.txt").path
        {
            if let fileHandle = FileHandle(forWritingAtPath: path)
            {
                //append to file
                fileHandle.seekToEndOfFile()
                fileHandle.write(contentString.data(using: String.Encoding.utf8)!)
            }
            else
            {
                //create new file
                do
                {
                    try contentString.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
                }
                catch
                {
                    print("Error writing to file \(path)")
                }
            }
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

}
