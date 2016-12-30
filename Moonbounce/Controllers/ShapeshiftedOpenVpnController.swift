//
//  ShapeshiftedOpenVpnController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/21/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

class ShapeshiftedOpenVpnController: NSObject
{
    static var openVPN = OpenVPN()
    
    public func start(completion:@escaping (_ launched:Bool) -> Void)
    {
        ShapeshifterDispatcherController.sharedInstance.launchShapeshifterDispatcherClient()
        
        ShapeshiftedOpenVpnController.openVPN.start
        {
            (didConnect) in
            
            print("OpenVPN connect process did complete: \(didConnect)")
        }
    }
    
    public func stop(completion:(_ stopped:Bool) -> Void)
    {
        ShapeshifterDispatcherController.sharedInstance.stopShapeshifterDispatcherClient()
        ShapeshiftedOpenVpnController.openVPN.stop
        {
            (didStop) in
            
            print("OpenVPN did stop: \(didStop)")
        }
    }
    
    
}
