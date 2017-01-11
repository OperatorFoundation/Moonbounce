//
//  TerraformController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/21/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class TerraformController: NSObject
{
    var terraformTask: Process!
    let outputPipe = Pipe()
    let ipFilePath = userConfigDirectory.appending("/serverIP")
    
    func launchTerraformServer(completion:@escaping (_ completion:Bool) -> Void)
    {
        let bundle = Bundle.main
        guard let path = bundle.path(forResource: "LaunchTerraformScript", ofType: "sh")
        else
        {
            print("Unable to launch Terraform server. Could not find the script.")
            return
        }
        
        runTerraformScript(path: path, arguments: nil)
        {
            (didLaunch) in
            
            if didLaunch
            {
                //Get the file that has the server IP
                if userConfigDirectory != ""
                {
                    do
                    {
                        let ip = try String(contentsOfFile: self.ipFilePath, encoding: String.Encoding.ascii)
                        userServerIP = ip
                        print("User Server IP is: \(ip)")
                    }
                    catch
                    {
                        print("Unable to locate the user server IP at: \(self.ipFilePath))")
                        completion(false)
                    }
                }
                
                completion(true)
            }
            else
            {
                completion(false)
            }
        }
    }
    
    func destroyTerraformServer(completion:@escaping (_ completion:Bool) -> Void)
    {
        guard let path = Bundle.main.path(forResource: "DestroyTerraform", ofType: "sh") else
        {
            print("Unable to destroy Terraform server. Could not find the script.")
            return
        }
        
        if terraformTask != nil
        {
            if terraformTask.isRunning
            {
                terraformTask.terminate()
            }
        }

        runTerraformScript(path: path, arguments: nil)
        {
            (didDestroy) in
            
            //Remove IP File as we check for this to verify if ther is a live server
            userServerIP = ""
            let fileManager = FileManager.default
            do
            {
                try fileManager.removeItem(atPath: self.ipFilePath)
            }
            catch let error as NSError
            {
                print("Error deleting IP file: \(error.debugDescription)")
            }
            
            completion(didDestroy)
        }
    }
    
    func runTerraformScript(path: String, arguments: [String]?, completion:@escaping (_ completion:Bool) -> Void)
    {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async
        {
            self.terraformTask = Process()
            self.terraformTask.launchPath = path
            self.terraformTask.terminationHandler =
            {
                 (task) in
                
                //Main Thread Stuff Here If Needed
                DispatchQueue.main.async(execute:
                {
                    print("Terraform Script Has Terminated.")
                    
                    //TODO: Fetch the new server IP
                    
                    completion(true)
                })
            }

            self.terraformTask.launch()
        }
    }
    
    func captureStandardOutput(_ task: Process)
    {
        //outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        //Waiting for output on a background thread
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        //Whenever data is available, waitForDataInBackgroundAndNotify notifies you by calling the block of code you register with NSNotificationCenter 
        //to handle NSFileHandleDataAvailableNotification.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading.availableData, queue: nil)
        {
            (notification) in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8)
            
            DispatchQueue.main.async(execute:
            {
                print("\nTerraform Standard Output:\n \(outputString)\n")
            })
        }
        
        self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }
    
    func createVarsFile(token: String)
    {
        let bundle = Bundle.main
        guard let path = bundle.path(forResource: "vars", ofType: nil)
            else
        {
            print("Unable to copy vars template, template could not be found in the app bundle.")
            return
        }
        
        do
        {
            //TODO: replace this with the directory we wil be installing this on
            let shapeshifterServerVarsPath = "/Volumes/extDrive/Code/shapeshifter-server/vars"
            try FileManager.default.copyItem(atPath: path, toPath: shapeshifterServerVarsPath)
            
            //If we successfully copied over a vars template, append the user token and config directory lines
            if FileManager.default.fileExists(atPath: shapeshifterServerVarsPath)
            {
                let tokenString = "export TF_VAR_do_token=\"\(token)\""
                let directoryString = "export TF_VAR_config_dir=\"\(userConfigDirectory)\""
                let stringToAppend = "\(tokenString)\n\(directoryString)"
                if let dataToAppend =  stringToAppend.data(using: String.Encoding.ascii)
                {
                    if let varsFileHandle = FileHandle(forWritingAtPath: shapeshifterServerVarsPath)
                    {
                        varsFileHandle.seekToEndOfFile()
                        varsFileHandle.write(dataToAppend)
                        varsFileHandle.closeFile()
                    }
                    else
                    {
                        print("Can't open file handle for updating vars file.")
                    }
                }
                else
                {
                    print("Unable to convert new vars lines to data to append")
                }
            }
        }
        catch
        {
            print("Unable to copy vars template to shapeshifter server directory:\n \(error)")
        }
    }
    
}
