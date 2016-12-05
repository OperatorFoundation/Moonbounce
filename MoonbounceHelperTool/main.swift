//
//  main.swift
//  MoonbounceHelperTool
//
//  Created by Adelita Schule on 11/30/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

public class Main: NSObject
{
    static var connectTask:Process!
    var verbosity = 3
    
    func startOpenVPN(appDirectory: String, configFileName: String, kextFilePath: String, completion:@escaping (_ launched:Bool) -> Void)
    {
        //We need TUN Kernel Extension in order to connect to OpenVPN
        loadKextScript(arguments: kextArguments(kextFilePath: kextFilePath))
        
        //Path to script file
        guard let path = Bundle.main.path(forResource: "openvpn", ofType: nil)
            else
        {
            print("Unable to locate openVPN program")
            return
        }
        
        //Arguments
        let openVpnArguments = connectToOpenVPNArguments(directory: appDirectory, configFileName: configFileName)
        
        runOpenVpnScript(path, arguments: openVpnArguments)
        {
            (wasLaunched) in
            
            completion(wasLaunched)
        }
    }
    
    func stopOpenVPN(kextFilePath: String)
    {
        //Unload the TUN Kext
        unloadKextScript(arguments: kextArguments(kextFilePath: kextFilePath))
        
        //Disconnect OpenVPN
        if Main.connectTask != nil
        {
            Main.connectTask!.terminate()
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
        processArguments.append("--management")
        processArguments.append("127.0.0.1")
        processArguments.append("1337")
        processArguments.append("--management-query-passwords")
        //processArguments.append("--management-hold")
        
        return processArguments
    }
    
    private func kextArguments(kextFilePath: String) -> [String]
    {
        //List of arguments for Process/Task
        var processArguments: [String] = []
        
        processArguments.append(kextFilePath)
        
        return processArguments
    }
    
    private func runOpenVpnScript(_ path: String, arguments: [String], completion:@escaping (_ launched: Bool) -> Void)
    {
        //Run heavy lifting on the background thread.
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async
            {
                //Creates a new Process and assigns it to the connectTask property.
                Main.connectTask = Process()
                //The launchPath is the path to the executable to run.
                Main.connectTask.launchPath = path
                //Arguments will pass the arguments to the executable, as though typed directly into terminal.
                Main.connectTask.arguments = arguments
                
                //Do something after the process (FKA NSTask) is finished
                Main.connectTask.terminationHandler =
                    {
                        task in
                        
                        //TODO: Give actual results one day
                        completion(true)
                }
                
                self.addOutputObserver(process: Main.connectTask, outputPipe: Pipe())
                
                //Go ahead and launch the process/task
                Main.connectTask.launch()
                
                //Block any other activity on this thread until the process/task is finished
                Main.connectTask.waitUntilExit()
                
                if !Main.connectTask.isRunning
                {
                    let status = Main.connectTask.terminationStatus
                    
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
    }
    
    func loadKextScript(arguments: [String])
    {
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
                
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })
    }
    
    
}


