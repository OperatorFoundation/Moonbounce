//
//  HelperAppController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

class HelperAppController
{
    static var kHelperToolName:String = "org.OperatorFoundation.MoonbounceHelperTool"
    
    static var xpcServiceConnection: NSXPCConnection?

    static func connectToXPCService() -> MoonbounceHelperProtocol
    {
        // Create a connection to the service
        assert(Thread.isMainThread)
        if (self.xpcServiceConnection == nil)
        {
            self.xpcServiceConnection = NSXPCConnection(machServiceName:kHelperToolName, options:NSXPCConnection.Options.privileged)
            self.xpcServiceConnection!.remoteObjectInterface = NSXPCInterface(with:MoonbounceHelperProtocol.self)
            self.xpcServiceConnection!.invalidationHandler =
            {
                // If the connection gets invalidated then, on the main thread, nil out our
                // reference to it.  This ensures that we attempt to rebuild it the next time around.
                self.xpcServiceConnection!.invalidationHandler = nil
                OperationQueue.main.addOperation()
                {
                    self.xpcServiceConnection = nil
                    NSLog("connection invalidated\n")
                }
            }
        }
        
        self.xpcServiceConnection?.resume()
        return (self.xpcServiceConnection!.remoteObjectProxy as! MoonbounceHelperProtocol)
    }

}
