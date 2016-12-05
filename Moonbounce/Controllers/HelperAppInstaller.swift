//
//  HelperAppInstaller.swift
//  Moonbounce
//
//  Created by Adelita Schule on 11/28/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import ServiceManagement
import SecurityFoundation

class HelperAppInstaller: NSObject
{
    //SMJobBless:  Apple's recommended way of running privileged helper
    static func blessHelper(label:String) -> Bool
    {
        //TODO: Check to see if a queue directory exists or create it for start and stop files
        /*The launchd daemon starts your job whenever the given directories are non-empty, and it keeps your job running as long as those directories are not empty*/
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
                }
                
                //Application Queue Directory
                let queueDirectoryPath = directoryPath.appendingPathComponent("moonbounceqdir", isDirectory: true)
                
                do
                {
                    try fileManager.createDirectory(at: queueDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let queueDirError
                {
                    print(queueDirError)
                }
            }
        }
        
        var result = false
        
        // Obtain an Authorization Reference
        // You can do this at the beginning of the app. It has no extra rights until later
        var authRef: AuthorizationRef? = nil
        
        
        
        //Ask user for admin privilege
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        let status = AuthorizationCreate(&authRights, nil, flags, &authRef)
        
        // There's really no reason for this to fail, but let's be careful
        guard status == errAuthorizationSuccess
            else
        {
            fatalError("Cannot create AuthorizationRef: \(status)")
        }

        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        
        //TODO: This label must be globally unique and matches the product name of your helper
        //This also *should* not fail
        let helperToolName = "org.OperatorFoundation.MoonbounceHelperTool"
        var cfError: Unmanaged<CFError>? = nil
        
        //Run the privileged helper
        result = SMJobBless(kSMDomainSystemLaunchd, helperToolName as CFString, authRef!, &cfError)
        
        if !result
        {
            let blessError = cfError!.takeRetainedValue()
            print("Elevating privileges failed: \(blessError)")
        }
        
        //Release the Authorization Reference
        AuthorizationFree(authRef!, [])
        return result
    }


}
