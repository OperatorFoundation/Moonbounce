//
//  MoonbounceViewController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import NetworkExtension
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
        nc.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil, using: neVPNStatusChanged)
        
        advancedModeButton.isHidden = true
        updateStatusUI(connected: false, statusDescription: "Not Connected")

        self.worker.async
        {
            let appId = Bundle.main.bundleIdentifier!
            let configURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("moonbounce.json")
            
            do
            {
                let decoder = JSONDecoder()
                let decodedData = try Data(contentsOf: configURL)
                let clientConfig = try decoder.decode(ClientConfig.self, from: decodedData)
                
                guard clientConfig.serverPublicKey.data != nil else
                {
                    throw MoonbounceConfigError.serverPublicKeyInvalid
                }
                                
                let shadowConfig = try ShadowConfig.ShadowClientConfig(serverAddress: "\(clientConfig.host):\(UInt16(clientConfig.port))", serverPublicKey: clientConfig.serverPublicKey, mode: .DARKSTAR)
                
                print("☾ Saving moonbounce configuration with \nip: \(clientConfig.host)\nport: \(clientConfig.port)\nproviderBundleIdentifier: \(appId).NetworkExtension")
                try self.moonbounce.configure(shadowConfig, providerBundleIdentifier: "\(appId).NetworkExtension", tunnelName: "MoonbounceTunnel")
            }
            catch
            {
                print("☾ Failed to load the moonbounce configuration file at \(configURL.path()) please ensure that you have a valid file at this location.")
                print("☾ error loading configuration file: \(error)")
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
        print("☾ Received a status changed notification:")
        
        if let session = notification.object as? NETunnelProviderSession
        {
            let status = session.status
            self.printConnectionStatus(status: status)
        }
        else
        {
            print("☾ \(notification.object!)")
        }
        
//        showStatus()
    }
    
    func neVPNStatusChanged(notification: Notification)
    {
        print("☾ Received a neVPNStatusChanged changed notification:")
        
        if let session = notification.object as? NETunnelProviderSession
        {
            let status = session.status
            self.printConnectionStatus(status: status)
        }
        else
        {
            print("☾ \(notification.object!)")
        }
        
//        showStatus()
    }
    
    func printConnectionStatus( status: NEVPNStatus )
    {
        switch status 
        {
            case NEVPNStatus.invalid:
                print("☾ NEVPNConnection: Invalid")
                isConnected = .failed
                updateStatusUI(connected: false, statusDescription: "Invalid")
            case NEVPNStatus.disconnected:
                print("☾ NEVPNConnection: Disconnected")
                isConnected = .start
                updateStatusUI(connected: false, statusDescription: "Disconnected")
            case NEVPNStatus.connecting:
                print("☾ NEVPNConnection: Connecting")
                isConnected = .trying
                updateStatusUI(connected: false, statusDescription: "Connecting")
            case NEVPNStatus.connected:
                print("☾ NEVPNConnection: Connected")
                isConnected = .success
                updateStatusUI(connected: true, statusDescription: "Connected")
            case NEVPNStatus.reasserting:
                print("☾ NEVPNConnection: Reasserting")
                isConnected = .trying
                updateStatusUI(connected: true, statusDescription: "Reasserting")
            case NEVPNStatus.disconnecting:
                print("☾ NEVPNConnection: Disconnecting")
                isConnected = .success
                updateStatusUI(connected: true, statusDescription: "Disconnecting")
            default:
                print("☾ NEVPNConnection: Unknown Status")
                isConnected = .failed
                updateStatusUI(connected: false, statusDescription: "Unknown")
      }
    }
    
    //MARK: Action!
    @IBAction func toggleConnection(_ sender: NSButton)
    {
        print("☾ User toggled connection switch.")
        switch isConnected
        {
            case .start:
                print("☾ Calling connect()")
                connect()
            case .trying:
                print("☾ Calling disconnect()")
                disconnect()
            case .success:
                print("☾ Calling disconnect()")
                disconnect()
            case .failed:
                print("☾ Calling connect()")
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
        print("☾ Share services: \(proposedServices)")
        
        return proposedServices
    }
    
    
    func connect()
    {
        isConnected = .trying

        runBackgroundAnimation()
        runningScript = true
        
        // Update button name
        self.toggleConnectionButton.title = "Disconnect"

        Asynchronizer.asyncThrows(moonbounce.startVPN)
        {
            maybeError in

            if let error = maybeError
            {
                isConnected = .failed
                print("☾ moonbounce.startVPN() returned an error: \(error). Setting state to failed.")

                DispatchQueue.main.async
                {
                    self.showStatus()
                }
            }
            else
            {
                // Verify that connection was successful and update accordingly
                print("☾ moonbounce.startVPN() returned without error. Setting isConnected.state to success and the stage to statusCodes.")
                self.runningScript = false
                isConnected = .success

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
                print("☾ Failed to disconnect from the VPN. Error: \(error)")
//                appLog.error("Failed to disconnect from the VPN. Error: \(error)")
            }

            self.runningScript = false
        }
    }
    
    // MARK: - UI Helpers
    func showStatus()
    {
        switch isConnected
        {
            case .start:
                self.updateStatusUI(connected: false, statusDescription: "Not Connected")
            case .trying:
                self.updateStatusUI(connected: true, statusDescription: "Getting VPN Status")
            case .success:
                self.updateStatusUI(connected: true, statusDescription: "Connected")
            case .failed:
                self.updateStatusUI(connected: false, statusDescription: "Failed to connect  to VPN")
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
                if isConnected == .trying
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

public enum MoonbounceConfigError: Error {
    case serverPublicKeyInvalid
}
