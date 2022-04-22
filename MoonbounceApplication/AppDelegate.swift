//
//  AppDelegate.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import Logging
import MoonbounceLibrary

let statusBarIcon = "icon"
let statusBarAlternateIcon = "iconWhite"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, FileManagerDelegate
{
    @IBOutlet weak var window: NSWindow!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    let menu = NSMenu()
    let fileManager = FileManager.default
    
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        // Setup the logger
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        appLog.logLevel = .debug
        
        // Setup the status bar item/button
        if let moonbounceButton = statusItem.button
        {
            moonbounceButton.image = NSImage(named: statusBarIcon)
            moonbounceButton.alternateImage = NSImage(named: statusBarAlternateIcon)
            moonbounceButton.target = self
            moonbounceButton.action = #selector(self.statusBarIconClicked)
            moonbounceButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup the right-click menu
        menu.addItem(withTitle: "Quit Moonbounce", action: #selector(self.quitMoonbounce), keyEquivalent: "q")
        
        // Show them our pretty things in this VC
        popover.contentViewController = MoonbounceViewController(nibName: "MoonbounceViewController", bundle: nil)

        // If user clicks away close the popover (get outta the way)
        eventMonitor = EventMonitor(mask: .leftMouseDown, handler:
        { (event) in
            if self.popover.isShown
            {
                self.closePopover(sender: event)
            }
        })
        
        // Cocoa normally keeps you from launching more than one instance at a time, but sometimes it happens anyway
        if let bundleID = Bundle.main.bundleIdentifier
        {
            if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1
            {
                //Activate the existing instance and lose this one
                let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                for app in apps
                {
                    if app != NSRunningApplication.current
                    {
                        app.activate(options: [])
                    }
                }
            }
        }
        
        // Check for config directories, if they don't exist, create them
        fileManager.delegate = self
//        Moonbounce.createServerConfigDirectories()
//        Moonbounce.checkForServerIP()
    }
        
    func showPopover(sender: AnyObject?)
    {
        if let moonbounceButton = statusItem.button
        {
            popover.show(relativeTo: moonbounceButton.bounds, of: moonbounceButton, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }
    
    func closePopover(sender: AnyObject?)
    {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    //Show them our pretty things, or maybe hide them
    func togglePopover(sender: AnyObject?)
    {
        if popover.isShown
        {
            closePopover(sender: sender)
        }
        else
        {
            showPopover(sender: sender)
        }
    }
    
    @objc func statusBarIconClicked(sender: NSStatusBarButton)
    {
        if let event = NSApp.currentEvent
        {
            if event.type == NSEvent.EventType.rightMouseUp // Show the right-click menu
            {
                // If the main view/popup is open close it
                closePopover(sender: nil)
                
                // Setup and display the right-click menu
                let popUpPosition = NSPoint(x: (statusItem.button!.bounds.width * 0.9), y: statusItem.button!.bounds.height)
                statusItem.menu = menu
                menu.popUp(positioning: nil, at: popUpPosition, in: statusItem.button)
                
                // This is necessary for button clicks to continue to be processed correctly
                statusItem.menu = nil
            }
            else
            {
                togglePopover(sender: nil) // Show/hide the main view
            }
        }
    }
    
    @objc func quitMoonbounce(sender: AnyObject?)
    {
        NSApplication.shared.terminate(sender)
    }
    
    func applicationWillTerminate(_ aNotification: Notification)
    {
        // TODO: implement me
    }
}

