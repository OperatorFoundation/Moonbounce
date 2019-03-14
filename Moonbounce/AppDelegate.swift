//
//  AppDelegate.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa

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
        //Set up the status bar item/button
        if let moonbounceButton = statusItem.button
        {
            moonbounceButton.image = NSImage(named: statusBarIcon)
            moonbounceButton.alternateImage = NSImage(named: statusBarAlternateIcon)
            moonbounceButton.target = self
            moonbounceButton.action = #selector(self.statusBarIconClicked)
            moonbounceButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        //Set up the right-click menu
        menu.addItem(withTitle: "Quit Moonbounce", action: #selector(self.quitMoonbounce), keyEquivalent: "q")
        
        //Show them our pretty things in this VC
        popover.contentViewController = MoonbounceViewController(nibName: "MoonbounceViewController", bundle: nil)

        //If user clicks away close the popover (get outta the way)
        eventMonitor = EventMonitor(mask: .leftMouseDown, handler: { (event) in
            if self.popover.isShown
            {
                self.closePopover(sender: event)
            }
        })
        
        //Cocoa normally keeps you from launching more than one instance at a time, but sometimes it happens anyway
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
        
        //Check for config directories, if they don't exist, create them
        fileManager.delegate = self
        createServerConfigDirectories()
        checkForServerIP()
    }
    
//    func application(_ sender: NSApplication, openFile filename: String) -> Bool
//    {
//        print("Attempted to open a file: \(filename)")
//        let tunnelController = TunnelController()
//        serverManager.addServer(withConfigFilePath: filename)
//
//        return true
//    }
    
    func checkForServerIP()
    {
        // Try finding a user created server first
        let userConfigURL = userConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
        
        if let userConfig = ClientConfig(withConfigAtPath: userConfigURL.path)
        {
            userHost = userConfig.host
            return
        }
        
        // Next try finding the first available imported server
        if let importedDirectories = fileManager.subpaths(atPath: importedConfigDirectory.path),
            importedDirectories.count > 0,
            let importedClientConfig = ClientConfig(withConfigAtPath: importedDirectories[0])
        {
            userHost = importedClientConfig.host
            return
        }
        
        // If no user or imported servers exist use the default
        let defaultConfigURL = defaultConfigDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
        
        if let defaultClientConfig = ClientConfig(withConfigAtPath: defaultConfigURL.path)
        {
            userHost = defaultClientConfig.host
            return
        }
        else
        {
            // TODO: Notify user when host information cannot be found
            print("\nUnable to find config directories at: \(defaultConfigURL)\n")
        }
    }
    
    func createServerConfigDirectories()
    {
        // Imported config files directory - Configurations imported by the user via the file system
        // If the directory does not exist, this method creates it.
        do
        {
            try fileManager.createDirectory(at: importedConfigDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        catch let importedConfigError
        {
            print(importedConfigError)
        }
        
        // User Config Directory - Created when the user launches a Digital Ocean server through our app
        // TODO: We may want to allow for and account for multiple user created servers
        do
        {
            try fileManager.createDirectory(at: userConfigDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        catch let userConfigError
        {
            print(userConfigError)
        }
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
            if event.type == NSEvent.EventType.rightMouseUp
            {
                closePopover(sender: nil)
                statusItem.menu = menu
                //statusItem.popUpMenu(menu)
                
                // This is critical, otherwise clicks won't be processed again
                statusItem.menu = nil
            }
            else
            {
                togglePopover(sender: nil)
            }
        }
    }
    
    @objc func quitMoonbounce(sender: AnyObject?)
    {
        NSApplication.shared.terminate(sender)
    }
    
    func applicationWillTerminate(_ aNotification: Notification)
    {
        //TODO: Attempt to disconnect when the app is closed
    }


}

