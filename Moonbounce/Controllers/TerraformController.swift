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
    
    // TODO: We used to create and destroy an ipFile, terraform needs to create a client config file instead
    let clientConfigURL = userConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
    
    func launchTerraformServer(completion:@escaping (_ completion:Bool) -> Void)
    {
        let bundle = Bundle.main
        
        guard let terrPath = bundle.path(forResource: "terraform", ofType: nil)
        else
        {
            print("Unable to launch terraform server. Could not find terraform executable.")
            return
        }
        
        guard let path = bundle.path(forResource: "LaunchTerraformScript", ofType: "sh")
        else
        {
            print("Unable to launch Terraform server. Could not find the script.")
            return
        }
        
        guard let shapeshifterServerPath = Bundle.main.path(forResource: "shapeshifter-server", ofType: nil)
        else
        {
            print("Unable to launch terraform server. Could not find shapeshifter server executable.")
            return
        }
        
        runTerraformScript(path: path, arguments: [terrPath, shapeshifterServerPath])
        {
            (didLaunch) in
            
            if didLaunch
            {
                // Get client config from user config directory
                
                
                guard let clientConfig = ClientConfig(withConfigAtPath: self.clientConfigURL.path)
                else
                {
                    print("Unable to locate the new user server IP at: \(self.clientConfigURL))")
                    print("Perhaps we were unable to launch a new DO server.")
                    completion(false)
                    return
                }
                
                userHost = clientConfig.host
                completion(true)
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
        
        guard let terrPath = Bundle.main.path(forResource: "terraform", ofType: nil)
            else
        {
            print("Unable to launch terraform server. Could not find terraform executable.")
            return
        }
        
        guard let shapeshifterServerPath  = Bundle.main.path(forResource: "shapeshifter-server", ofType: nil)
            else
        {
            print("Unable to launch terraform server. Could not find shapeshifter server executable.")
            return
        }
        
        if terraformTask != nil
        {
            if terraformTask.isRunning
            {
                terraformTask.terminate()
            }
        }
        
        //Running the destroy terraform script. Kill the server!
        runTerraformScript(path: path, arguments: [terrPath, shapeshifterServerPath])
        {
            (didDestroy) in
            
            //Let's do this a second time to be sure.
            self.runTerraformScript(path: path, arguments: [terrPath, shapeshifterServerPath], completion:
            {
                (didDestroy) in
                
                //Remove IP File as we check for this to verify if there is a live server available.
                userHost = nil
                let fileManager = FileManager.default
                do
                {
                    try fileManager.removeItem(atPath: self.clientConfigURL.path)
                }
                catch let error as NSError
                {
                    print("Error deleting IP file: \(error.debugDescription)")
                }
                
                completion(didDestroy)
            })
        }
    }
    
    func runTerraformScript(path: String, arguments: [String]?, completion:@escaping (_ completion:Bool) -> Void)
    {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async
        {
            self.terraformTask = Process()
            self.terraformTask.launchPath = path
            self.terraformTask.arguments = arguments
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

            //self.captureStandardOutput(self.terraformTask)
            self.terraformTask.launch()
        }
    }
    
    func captureStandardOutput(_ task: Process)
    {
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
                print("\nTerraform Standard Output:\n \(String(describing: outputString))\n")
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
            guard let shapeshifterServerPath = bundle.path(forResource: "shapeshifter-server", ofType: nil)
            else
            {
                print("Unable to copy vars template as the shapeshifter server directory could not be found.")
                return
            }
            let shapeshifterServerVarsPath = shapeshifterServerPath.appending("/vars")
            let fileManager = FileManager.default
            
            //If a previous vars file is already here, delete it so we can have the new token
            if fileManager.fileExists(atPath: shapeshifterServerVarsPath)
            {
                do
                {
                    try fileManager.removeItem(atPath: shapeshifterServerVarsPath)
                }
                catch
                {
                    print("Vars file already exists at path:\n\(shapeshifterServerVarsPath)")
                    print("Unable to delete existing vars file:\n\(error.localizedDescription)")
                }
            }
            
            //Copy over the vars template
            try fileManager.copyItem(atPath: path, toPath: shapeshifterServerVarsPath)
            
            //If we successfully copied over a vars template, append the user token and config directory lines
            if fileManager.fileExists(atPath: shapeshifterServerVarsPath)
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
