//
//  EventMonitor.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

public class EventMonitor
{
    private var monitor: AnyObject?
    private let mask: NSEventMask
    private let handler: (NSEvent?) -> ()
    
    public init(mask: NSEventMask, handler: @escaping (NSEvent?) -> ())
    {
        self.mask = mask
        self.handler = handler
    }
    
    public func start()
    {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject?
    }
    
    public func stop()
    {
        if monitor != nil
        {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
    
    deinit
    {
        self.stop()
    }
}
