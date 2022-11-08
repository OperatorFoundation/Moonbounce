//
//  MoonbounceViewController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import os.log

import Chord
import MoonbounceLibrary
import MoonbounceShared
import ShadowSwift

class MoonbounceViewController: NSViewController, NSSharingServicePickerDelegate
{
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var advancedModeButton: NSButton!
    @IBOutlet weak var toggleConnectionButton: CustomButton!
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var laserImageView: NSImageView!
    @IBOutlet weak var laserLeadingConstraint: NSLayoutConstraint!

    @objc dynamic var runningScript = false
    
    //Advanced Mode Outlets
    @IBOutlet weak var advModeHeightConstraint: NSLayoutConstraint!
    
    let proximaNARegular = "Proxima Nova Alt Regular"
    let advancedMenuHeight: CGFloat = 176.0
    let moonbounce = MoonbounceLibrary(logger: Logger(subsystem: "org.OperatorFoundation.MoonbounceLogger", category: "NetworkExtension"))
    var loggingEnabled = false

    let worker: DispatchQueue = DispatchQueue(label: "MoonbounceViewController.worker")
    
    //MARK: View Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name(rawValue: kConnectionStatusNotification), object: nil, queue: nil, using: connectionStatusChanged)
        nc.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil, using: connectionStatusChanged)
        
        advancedModeButton.isHidden = true
        updateStatusUI(connected: false, statusDescription: "Not Connected")

        self.worker.async
        {
            do
            {
                let appId = Bundle.main.bundleIdentifier!
                let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("shadowClient.json").path
                
                guard let shadowConfig = ShadowConfig(path: configPath) else
                {
                    appLog.error("Failed to find a valid Shadow config file.")
                    return
                }
                
                print("Saving moonbounce configuration with \nip: \(shadowConfig.serverIP)\nport: \(shadowConfig.port)\nproviderBundleIdentifier: \(appId).NetworkExtension")
                try self.moonbounce.configure(shadowConfig, providerBundleIdentifier: "\(appId).NetworkExtension", tunnelName: "MoonbounceTunnel")
            }
            catch
            {
                appLog.error("error loading configuration: \(error)")
            }
        }
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        self.styleViews()
    }
    
    func connectionStatusChanged(notification: Notification)
    {
        showStatus()
    }
    
    //MARK: Action!
    @IBAction func toggleConnection(_ sender: NSButton)
    {
        switch isConnected.state
        {
            case .start:
                switch isConnected.stage
                {
                    case .start:
                        appLog.info("Connect button pressed")
                        self.connect()
                    default:
                        appLog.error("Error: Connected state of Start but Stage is \(isConnected.stage)")
                }
            case .trying:
                switch isConnected.stage
                {
                    case .start:
                        //Should Not Happen
                        appLog.error("Error: Connected state of Trying but Stage is Start")
                    default:
                        //Disconnect from VPN server
                        disconnect()
                }
            case .success:
                disconnect()
            case .failed:
                connect()
        }
    }
    
    @IBAction func showAdvancedMode(_ sender: AnyObject)
    {
        if advModeHeightConstraint.constant > 0
        {
            closeMenu(sender: sender)
        }
        else
        {
            showMenu(sender: sender)
        }
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService]
    {
        appLog.debug("Share services: \(proposedServices)")
        return proposedServices
    }
    
    
    func connect()
    {
        isConnected.stage = .start
        isConnected.state = .trying

        runBackgroundAnimation()
        isConnected = ConnectState(state: .start, stage: .start)
        runningScript = true
        
        //Update button name
        self.toggleConnectionButton.title = "Disconnect"

        Asynchronizer.asyncThrows(moonbounce.startVPN)
        {
            maybeError in

            if let error = maybeError
            {
                isConnected.state = .failed
                appLog.error("failed to start VPN: \(error)")

                DispatchQueue.main.async
                {
                    self.showStatus()
                }
            }
            else
            {
                //Verify that connection was successful and update accordingly
                self.runningScript = false
                isConnected.state = .success
                isConnected.stage = .statusCodes

                DispatchQueue.main.async
                {
                    self.showStatus()
                }
            }
        }
    }
        
    func disconnect()
    {
        Asynchronizer.asyncThrows(moonbounce.stopVPN)
        {
            maybeError in

            if let error = maybeError
            {
                appLog.error("failed to disconnect from VPN: \(error)")
            }

            self.runningScript = false
        }
    }
    
    // MARK: - UI Helpers
    func showStatus()
    {
        switch isConnected.state
        {
            case .start:
                switch isConnected.stage
                {
                    case .start:
                        self.updateStatusUI(connected: false, statusDescription: "Not Connected")
                    default:
                        appLog.error("Error: Connected state of Start but Stage is \(isConnected.stage)")
                }
            case .trying:
                switch isConnected.stage
                {
                    case .start:
                        //Should Not Happen
                        appLog.error("Error: Connected state of Trying but Stage is Start")
                    case .dispatcher:
                        self.updateStatusUI(connected: true, statusDescription: "Starting Dispatcher")
                    case .management:
                        self.updateStatusUI(connected: true, statusDescription: "Connecting to the Management Server")
                    case .statusCodes:
                        self.updateStatusUI(connected: true, statusDescription: "Getting VPN Status")
                }
            case .success:
                switch isConnected.stage
                {
                    case .start:
                        //Should Not Happen
                        appLog.error("Error: Connected state of Success but Stage is Start")
                    case .dispatcher:
                        self.updateStatusUI(connected: true, statusDescription: "Started Dispatcher")
                    case .management:
                        self.updateStatusUI(connected: true, statusDescription: "Connected to the Management Server")
                    case .statusCodes:
                        self.updateStatusUI(connected: true, statusDescription: "Connected")
                }
            case .failed:
                switch isConnected.stage
                {
                    case .start:
                        //Should Not Happen
                        appLog.error("Error: Connected state of Failed but Stage is Start")
                    case .dispatcher:
                        self.updateStatusUI(connected: false, statusDescription: "Failed to start Dispatcher")
                    case .management:
                        self.updateStatusUI(connected: false, statusDescription: "Failed to Connect to the Management Server")
                    case .statusCodes:
                        self.updateStatusUI(connected: false, statusDescription: "Failed to connect  to VPN")
            }
        }
    }
    

    func styleViews()
    {
        //Connection Button and label Styling
        showStatus()
                
        //Advanced Mode Button
        if let menuButtonFont = NSFont(name: proximaNARegular, size: 18)
        {
            let menuButtonAttributes = [NSAttributedString.Key.foregroundColor: NSColor.white,
                                        NSAttributedString.Key.font: menuButtonFont]
            advancedModeButton.attributedTitle = NSAttributedString(string: "Advanced Mode", attributes: menuButtonAttributes)
        }
        advancedModeButton.layer?.backgroundColor = .clear
        
        //Advanced Mode Box
        advModeHeightConstraint.constant = 0
    }

    
    func showMenu(sender: AnyObject?)
    {
        advModeHeightConstraint.constant = advancedMenuHeight
    }
    
    func closeMenu(sender: AnyObject?)
    {
        advModeHeightConstraint.constant = 0
    }
    
    func runBackgroundAnimation()
    {
        NSAnimationContext.runAnimationGroup(
        {
                (context) in
                context.duration = 0.75
                self.laserLeadingConstraint.animator().constant = 260
        },
        completionHandler:
        {
            NSAnimationContext.runAnimationGroup(
            {
                (context) in
                
                context.duration = 0.75
                self.laserLeadingConstraint.animator().constant = -5
            },
            completionHandler:
            {
                if isConnected.state == .trying
                //if self.runningScript == true
                {
                    self.runBackgroundAnimation()
                }
            })
        })
    }
    
    func updateStatusUI(connected: Bool, statusDescription: String)
    {
        DispatchQueue.main.async
        {
            //Update Connection Status Label
            self.statusLabel.stringValue = statusDescription
            
            if connected
            {
                //Update button name
                self.toggleConnectionButton.title = "Disconnect"
            }
            else
            {
                self.toggleConnectionButton.title = "Connect"
            }
            
            //Stop BG Animation
            self.runningScript = false
        }
    }
    
    @objc func animateLoadingLabel()
    {
        if statusLabel.stringValue == "Loading..."
        {
            statusLabel.stringValue = "Loading"
        }
        else
        {
            statusLabel.stringValue = "\(statusLabel.stringValue)."
        }
        
        perform(#selector(animateLoadingLabel), with: nil, afterDelay: 1)
    }
    
    //Helper for showing an alert.
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
