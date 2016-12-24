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
    
    func launchTerraformServer(completion:@escaping (_ completion:Bool) -> Void)
    {
        guard let path = Bundle.main.path(forResource: "LaunchTerraformScript", ofType: "sh")
        else
        {
            print("Unable to launch Terraform server. Could not find the script.")
            return
        }
        
        runTerraformScript(path: path, arguments: nil)
        {
            (didLaunch) in
            
            completion(didLaunch)
        }
    }
    
    func destroyTerraformServer(completion:@escaping (_ completion:Bool) -> Void)
    {
        guard let path = Bundle.main.path(forResource: "DestroyTerraform", ofType: "sh") else
        {
            print("Unable to destroy Terraform server. Could not find the script.")
            return
        }
        
        if terraformTask.isRunning
        {
            terraformTask.terminate()
        }
        
        runTerraformScript(path: path, arguments: nil)
        {
            (didDestroy) in
            
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
            
            //tells the Process object to block any further activity on the current (background) thread until the task is complete.
            self.terraformTask.waitUntilExit()
        }
    }
    
}
