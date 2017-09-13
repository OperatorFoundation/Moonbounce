//
//  KillAll.swift
//  transport-canary
//
//  Created by Adelita Schule on 7/10/17.
//
//

import Foundation

func killAll(processToKill: String)
{
    print("******* ☠️ KILLALL \(processToKill) CALLED ☠️ *******")
    
    let killTask = Process()
    
    //The launchPath is the path to the executable to run.
    killTask.launchPath = "/usr/bin/killall"
    //Arguments will pass the arguments to the executable, as though typed directly into terminal.
    killTask.arguments = [processToKill]
    
    //Go ahead and launch the process/task
    killTask.launch()
    killTask.waitUntilExit()
    sleep(2)
    
    //Do it again, maybe it doesn't want to die.
    
    let killAgain = Process()
    killAgain.launchPath = "/usr/bin/killall"
    killAgain.arguments = ["-9", processToKill]
    killAgain.launch()
    killAgain.waitUntilExit()
    sleep(2)
}
