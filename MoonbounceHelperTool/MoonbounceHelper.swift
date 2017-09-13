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
    let fixInternetPath = "Helpers/fixInternet.sh"
    
    fileprivate var listener:NSXPCListener
    fileprivate let kHelperToolMachServiceName = "org.OperatorFoundation.MoonbounceHelperTool"
    
    override init()
    {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = NSXPCListener(machServiceName:kHelperToolMachServiceName)
        super.init()
        self.listener.delegate = self
    }
    
    func run()
    {
        // Tell the XPC listener to start processing requests.
        writeToLog(logDirectory: appDirectory, content: "*****Run Was Called******")
        
        // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
        self.listener.resume()
        
        // Run the run loop forever.
        writeToLog(logDirectory: appDirectory, content: "^^^^^^We are about to RunLoop this thing up in here^^^^^^")
        RunLoop.current.run()
        writeToLog(logDirectory: appDirectory, content: "<<<<<<<Our RunLoop is over, it was good while it lasted.>>>>>>>>")
    }
    
    // Called by our XPC listener when a new connection comes in.  We configure the connection
    // with our protocol and ourselves as the main object.
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool
    {
        writeToLog(logDirectory: appDirectory, content: "****New Incoming Connection****")
        
        print("new incoming connection")
        
        // Configure the new connection and resume it. Because this is a singleton object, we set 'self' as the exported object and configure the connection to export the 'SMJobBlessHelperProtocol' protocol that we implement on this object.
        newConnection.exportedInterface = NSXPCInterface(with:MoonbounceHelperProtocol.self)
        newConnection.exportedObject = self;
        newConnection.resume()
        return true
    }
    
    func startOpenVPN(openVPNFilePath: String, configFilePath: String, configFileName: String)
    {
        writeToLog(logDirectory: appDirectory, content: "******* STARTOPENVPN CALLED *******")
        //Arguments
        let openVpnArguments = connectToOpenVPNArguments(directory: configFilePath, configFileName: configFileName)
        
        _ = runOpenVpnScript(openVPNFilePath, logDirectory: configFilePath, arguments: openVpnArguments)
        
        writeToLog(logDirectory: appDirectory, content: "START OPEN VPN END OF FUNCTION")
    }
    
    func stopOpenVPN()
    {
        writeToLog(logDirectory: appDirectory, content: "******* STOP OpenVpn CALLED *******")
        
        //Disconnect OpenVPN
        if MoonbounceHelper.connectTask != nil
        {
            MoonbounceHelper.connectTask!.terminate()
        }
        
        fixTheInternet()
        killAll(processToKill: "openvpn")
    }
    
    private func connectToOpenVPNArguments(directory: String, configFileName: String) -> [String]
    {
        //List of arguments for Process/Task
        var processArguments: [String] = []
        
        processArguments.append("--cd")
        processArguments.append(directory)
        
        //Specify the log file path
        processArguments.append("--log")
        processArguments.append("\(appDirectory)/openVPNLog.txt")
        
        //Verbosity of Output
        processArguments.append("--verb")
        processArguments.append(String(verbosity))
        
        //Config File to use
        processArguments.append("--config")
        processArguments.append(configFileName)
        
        //Make sure we are still in the correct working directory
        processArguments.append("--cd")
        processArguments.append(directory)

        //Set management options
        processArguments.append("--management")
        processArguments.append("127.0.0.1")
        processArguments.append("13374")
        processArguments.append("--management-query-passwords")
        
        return processArguments
    }
    
    private func runOpenVpnScript(_ path: String, logDirectory: String, arguments: [String]) -> Bool
    {
        writeToLog(logDirectory: appDirectory, content: "Helper func: runOpenVpnScript")
        
        //Creates a new Process and assigns it to the connectTask property.
        MoonbounceHelper.connectTask = Process()
        //The launchPath is the path to the executable to run.
        MoonbounceHelper.connectTask.launchPath = path
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        MoonbounceHelper.connectTask.arguments = arguments

        //Go ahead and launch the process/task
        MoonbounceHelper.connectTask.launch()
        
        //This may be a lie :(
        return true
    }
    
    func writeToLog(logDirectory: String, content: String)
    {
        let timeStamp = Date()
        let contentString = "\n\(timeStamp):\n\(content)\n"
        let logFilePath = logDirectory + "moonbounceLog.txt"
        
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath)
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
                try contentString.write(toFile: logFilePath, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
                print("Error writing to file \(logFilePath)")
            }
        }
    }
    
    func fixTheInternet()
    {
        let fixTask = Process()
        fixTask.launchPath = fixInternetPath
        fixTask.launch()
        print("Attempted to fix the internet!")
        fixTask.waitUntilExit()
    }

}
