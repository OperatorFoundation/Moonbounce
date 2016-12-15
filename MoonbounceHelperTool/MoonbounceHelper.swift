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
    }
    
    func testLog()
    {
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: ">>>>>>>Test Log Received<<<<<<<")
    }

    func test(callback: (String) -> Void)
    {
        callback("This is the test callback response")
    }
    
    func testStartOpenVPN(openVPNFilePath: String, configFilePath: String, configFileName: String)
    {
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: ">>>>>>>Test Started OpenVPN<<<<<<<")
        //writeToLog(logDirectory: logDirectory, content: "OpenVPNFilePath:\(openVPNFilePath)\nConfig File Filepath: \(configFilePath)\nConfig File Name: \(configFileName)")
    }
    
    func run()
    {
        // Tell the XPC listener to start processing requests.
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: "*****Run Was Called******")
        
        // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
        self.listener.resume()
        
        //TODO: TESTING ONLY
        //self.startOpenVPN(openVPNFilePath: "/Users/Lita/Library/Developer/Xcode/DerivedData/Moonbounce-aosqeamddmsgekczgdbfntvzubaw/Build/Products/Debug/Moonbounce.app/Contents/Resources/openvpn", configFilePath: "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/", configFileName: "DO.ovpn")
        
        // Run the run loop forever.
        writeToLog(logDirectory: logDirectory, content: "^^^^^^We are about to RunLoop this thing up in here^^^^^^")
        RunLoop.current.run()
        writeToLog(logDirectory: logDirectory, content: "<<<<<<<Our RunLoop is over, it was good while it lasted.>>>>>>>>")
    }
    
    // Called by our XPC listener when a new connection comes in.  We configure the connection
    // with our protocol and ourselves as the main object.
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool
    {
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: "****New Incoming Connection****")
        
        print("new incoming connection")
        
        // Configure the new connection and resume it. Because this is a singleton object, we set 'self' as the exported object and configure the connection to export the 'SMJobBlessHelperProtocol' protocol that we implement on this object.
        newConnection.exportedInterface = NSXPCInterface(with:MoonbounceHelperProtocol.self)
        newConnection.exportedObject = self;
        newConnection.resume()
        return true
    }
    
    func startOpenVPN(openVPNFilePath: String, configFilePath: String, configFileName: String)
    {
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: "******* STARTOPENVPN CALLED *******")
        //Arguments
        let openVpnArguments = connectToOpenVPNArguments(directory: configFilePath, configFileName: configFileName)
        
        _ = runOpenVpnScript(openVPNFilePath, logDirectory: configFilePath, arguments: openVpnArguments)
    }
    
    func stopOpenVPN()
    {
        let logDirectory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: logDirectory, content: "******* STOP OPENvpn CALLED *******")
        
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
    
    private func runOpenVpnScript(_ path: String, logDirectory: String, arguments: [String]) -> Bool
    {
        let directory = "/Users/Lita/Library/Application Support/org.OperatorFoundation.MoonbounceHelperTool/"
        writeToLog(logDirectory: directory, content: "Helper func: runOpenVpnScript")
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
                    self.writeToLog(logDirectory: logDirectory, content: outString)
                }
                
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let errorString = String(data: errorData, encoding: .utf8)
                {
                    if errorString != ""
                    {
                        print(errorString)
                        self.writeToLog(logDirectory: logDirectory, content: "Error: \(errorString)")
                    }
                }
                
                MoonbounceHelper.connectTask.waitUntilExit()
                
                let status = MoonbounceHelper.connectTask.terminationStatus
                self.writeToLog(logDirectory: logDirectory, content: "Termination Status: \(status)")
        //}
        
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

}
