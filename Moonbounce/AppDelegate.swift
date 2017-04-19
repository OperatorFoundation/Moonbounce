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

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let popover = NSPopover()
    let menu = NSMenu()
    let fileManager = FileManager.default
    
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        //Install God-Mode Helper
        if !HelperAppInstaller.blessHelper(label: "org.OperatorFoundation.MoonbounceHelperTool")
        {
            print("Could not install MoonbounceHelperTool")
        }
        else
        {
            helperClient = HelperAppController.connectToXPCService()
        }
        
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
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: { (event) in
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
                    if app != NSRunningApplication.current()
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
    
    func checkForServerIP()
    {
        //Get the file that has the server IP
        if userConfigDirectory != ""
        {
            let ipFileDirectory = userConfigDirectory.appending("/" + ipFileName)
            
            do
            {
                let ip = try String(contentsOfFile: ipFileDirectory, encoding: String.Encoding.ascii)
                userServerIP = ip
                print("User Server IP is: \(ip)")
            }
            catch
            {
                print("Unable to locate the server IP at: \(ipFileDirectory).")
            }
        }
        else if defaultConfigDirectory != ""
        {
            let ipFileDirectory = defaultConfigDirectory.appending("/" + ipFileName)
            
            do
            {
                let ip = try String(contentsOfFile: ipFileDirectory, encoding: String.Encoding.ascii)
                userServerIP = ip
                print("Default Server IP is: \(ip)")
            }
            catch
            {
                print("Unable to locate the default server IP at: \(ipFileDirectory).")
            }
        }
        else
        {
            print("Unable to find and config directories.")
        }
    }
    
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    {
        let copyError = error as NSError

        if copyError.code == NSFileWriteFileExistsError
        {
            return true
        }
        
        return false
    }
    
    func createServerConfigDirectories()
    {
        let appSupportDirectory = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        if appSupportDirectory.count > 0
        {
            if let bundleID: String = Bundle.main.bundleIdentifier
            {
                // Append the bundle ID to the URL for the
                // Application Support directory
                let directoryPath = appSupportDirectory[0].appendingPathComponent(bundleID)
                appDirectory = directoryPath.path

                //Server Config Files Directory
                let configFilesPath = directoryPath.appendingPathComponent("ConfigFiles", isDirectory: true)
                
                //Imported Config Files
                let importedConfigPath = configFilesPath.appendingPathComponent(importedDirectoryName, isDirectory: true)
                
                // If the directory does not exist, this method creates it.
                // This method is only available in OS X v10.7 and iOS 5.0 or later.
                do
                {
                    try fileManager.createDirectory(at: importedConfigPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let importedConfigError
                {
                    print(importedConfigError)
                }
                
                //Default Config
                let defaultConfigPath = configFilesPath.appendingPathComponent(defaultDirectoryName
                , isDirectory: true)
                defaultConfigDirectory = defaultConfigPath.path
                guard let resourcePath = Bundle.main.path(forResource: defaultDirectoryName, ofType: nil)
                else
                {
                    print("Unable to find Default Config files.")
                    return
                }
                
                do
                {
                    try FileManager.default.copyItem(atPath: resourcePath, toPath: defaultConfigPath.path)
                }
                catch
                {
                    print("Unable to copy default config files: \(error.localizedDescription)")
                }
                
                //User Config
                let userConfigPath = configFilesPath.appendingPathComponent(userDirectoryName + "/DO", isDirectory: true)
                userConfigDirectory = userConfigPath.path
                do
                {
                    try fileManager.createDirectory(at: userConfigPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch let userConfigError
                {
                    print(userConfigError)
                }
                
                configFilesDirectory = configFilesPath.path
            }
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
    
    func statusBarIconClicked(sender: NSStatusBarButton)
    {
        if let event = NSApp.currentEvent
        {
            if event.type == NSEventType.rightMouseUp
            {
                closePopover(sender: nil)
                statusItem.menu = menu
                statusItem.popUpMenu(menu)
                // This is critical, otherwise clicks won't be processed again
                statusItem.menu = nil
            }
            else
            {
                togglePopover(sender: nil)
            }
        }
    }
    
    func quitMoonbounce(sender: AnyObject?)
    {
        NSApplication.shared().terminate(sender)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

