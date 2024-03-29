//
//  MoonbounceViewController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import Logging
import MoonbounceLibrary

class MoonbounceViewController: NSViewController, NSSharingServicePickerDelegate
{
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var advancedModeButton: NSButton!
    @IBOutlet weak var toggleConnectionButton: CustomButton!
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var laserImageView: NSImageView!
    @IBOutlet weak var laserLeadingConstraint: NSLayoutConstraint!

    @objc dynamic var runningScript = false
//    static var terraformController = TerraformController()
    
    //Advanced Mode Outlets
    @IBOutlet weak var advModeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var serverSelectButton: NSPopUpButton!
    @IBOutlet weak var serverProgressBar: NSProgressIndicator!
    @IBOutlet weak var accountTokenBox: NSBox!
    @IBOutlet weak var accountTokenTextField: NSTextField!
    @IBOutlet weak var launchServerButton: CustomButton!
    @IBOutlet weak var serverStatusLabel: NSTextField!
    @IBOutlet weak var cancelLaunchButton: CustomButton!
    @IBOutlet weak var launchServerButtonCell: NSButtonCell!
    @IBOutlet weak var shareServerButton: NSButton!
    
    //accountTokenBox.hidden is bound to this var
    @objc dynamic var hasDoToken = false
    
    let proximaNARegular = "Proxima Nova Alt Regular"
    let advancedMenuHeight: CGFloat = 176.0
    //let tunnelController = TunnelController()
    let configController = ConfigController()
    
    
    //@objc dynamic var serverManagerReady = false
    var userServerIsConnected = false
    var launching = false
    var loggingEnabled = false
    
    //MARK: View Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //TODO: Hiding advanced more for now until we can update DO server functionality
        advancedModeButton.isHidden = true
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name(rawValue: kConnectionStatusNotification), object: nil, queue: nil, using: connectionStatusChanged)
        nc.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil, using: connectionStatusChanged)
        nc.addObserver(forName: NSNotification.Name(rawValue: kNewServerAddedNotification), object: nil, queue: nil, using: newServerAdded)
        //nc.addObserver(forName: NSNotification.Name(serverManagerReadyNotification), object: nil, queue: nil, using: serverManagerNotificationReceived)
        
        serverProgressBar.usesThreadedAnimation = true
        updateStatusUI(connected: false, statusDescription: "Not Connected")
        styleTokenTextField()
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
    
    func newServerAdded(notification: Notification)
    {
        populateServerSelectButton()
    }
    
//    func serverManagerNotificationReceived(notification: Notification)
//    {
//        appLogdebug("\nSERVER MANAGER READY\n")
//        // TODO: Address possible race condition
//        self.serverManagerReady = true
//        serverManager.refreshServers
//        {
//            self.populateServerSelectButton()
//        }
//        self.showStatus()
//    }
    
    //MARK: Action!
    @IBAction func toggleConnection(_ sender: NSButton)
    {
        switch isConnected.state
        {
            case .start:
                switch isConnected.stage
                {
                case .start:
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
    
    @IBAction func serverSelectionChanged(_ sender: NSPopUpButton)
    {
        if let selectedItemTitle = sender.selectedItem?.title
        {
            //Don't make our default server available to share
            if selectedItemTitle == defaultTunnelName
            {
                shareServerButton.isHidden = true
            }
            else
            {
                shareServerButton.isHidden = false
            }
            
            // Currently we do not support launching you own server
//            if let menuItem =  sender.menu?.item(withTitle: selectedItemTitle)
//            {
//                if let tunnel = menuItem.representedObject as? Tunnel
//                {
//                    setSelectedServer(tunnel: tunnel)
//                    appLog.debug("Setting selected server \(selectedItemTitle)")
//                }
//            }
        }
        else
        {
            appLog.error("Unable to understand server selection, we could not get an item title from the popup button.")
        }
    }
    
    //This allows the user to upload their own config files
    @IBAction func addFileClicked(_ sender: CustomButton)
    {
        let openDialog = NSOpenPanel()
        openDialog.title = "Select Your Server Config File"
        openDialog.prompt = "Select"
        openDialog.canChooseDirectories = false
        openDialog.canChooseFiles = true
        openDialog.allowsMultipleSelection = false
        openDialog.allowedFileTypes = ["moonbounce", "MOONBOUNCE"]

        if let presentingWindow = self.view.window
        {
            openDialog.beginSheetModal(for: presentingWindow)
            {
                (response) in
                
                guard response == NSApplication.ModalResponse.OK
                    else { return }

                if let chosenDirectory = openDialog.url
                {
                    guard self.configController.addConfig(atURL: chosenDirectory)
                        else
                    {
                        appLog.debug("Failed to add a selected config to the config controller.")
                        return
                    }
                }
                
                self.populateServerSelectButton()
            }
        }
    }
    
    //Button that allows users to save the current config directory to a directory of their choice in order to share it.
    @IBAction func shareServerClick(_ sender: NSButton)
    {
//        //make sure we have a config directory, and that it is not the default server config directory
//        guard let tunnel = selectedTunnel
//            else
//        {
//            appLog.error("\nUnable to share server. Current server not found.\n")
//            return
//        }
//
//        guard tunnel.name != defaultTunnelName
//        else
//        {
//            appLog.error("\nAttempted to share default server...\n")
//            return
//        }
//
//        if let presentingWindow = self.view.window
//        {
//            sender.isEnabled = false
//            serverSelectButton.isEnabled = false
//
//            var serverName = tunnel.name
//
//            let alert = serverManager.createServerNameAlert(defaultName: serverName)
//            alert.beginSheetModal(for: presentingWindow, completionHandler:
//            {
//                (response) in
//
//                if response == NSApplication.ModalResponse.alertFirstButtonReturn, let textField = alert.accessoryView as? NSTextField
//                {
//                    serverName = textField.stringValue
//                }
//
//                var zipPath = moonbounceDirectory.appendingPathComponent(serverName, isDirectory: false)
//                zipPath = zipPath.appendingPathExtension(moonbounceExtension)
//
//                //Zip the files and save to the temp directory.
//                do
//                {
//                    try FileManager.default.zipItem(at: configURL, to: zipPath)
//
//                    //Set up a sharing services picker
//                    let sharePicker = NSSharingServicePicker.init(items: [zipPath])
//
//                    sharePicker.delegate = self
//                    sharePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
//                }
//                catch
//                {
//                    appLog.error("\nUnable to zip config directory for export!\n")
//                }
//
//                sender.isEnabled = true
//                self.serverSelectButton.isEnabled = true
//            })
//        }
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService]
    {
        appLog.debug("Share services: \(proposedServices)")
        return proposedServices
    }
    
    @IBAction func toggleServerStatus(_ sender: NSButton)
    {
        if userServerIsConnected
        {
            killServer(sender)
        }
        else
        {
            launchServer(sender)
        }
    }
    
    func launchServer(_ sender: NSButton)
    {
        if let _ = KeychainController.loadToken()
        {
//            MoonbounceViewController.terraformController.createVarsFile(token: userToken)
            
            sender.isEnabled = false
            toggleConnectionButton.isEnabled = false
            startIncrementingProgress(by: 0.5)
            cancelLaunchButton.isHidden = false
            serverStatusLabel.stringValue = "Launching"
            launching = true
            animateLaunchingLabel()
            
//            MoonbounceViewController.terraformController.launchTerraformServer
//            {
//                (launched) in
//
//                sender.isEnabled = true
//                self.toggleConnectionButton.isEnabled = true
//                self.stopIncrementingProgress()
//                self.populateServerSelectButton()
//                self.showUserServerStatus()
//
//                appLog.debug("Launch server task exited.")
//                self.cancelLaunchButton.isHidden = true
//                self.launching = false
//            }
        }
        else
        {
            accountTokenBox.isHidden = false
        }
    }
    
    func startIncrementingProgress(by amount: Double)
    {
        serverProgressBar.doubleValue = 0.0
        serverProgressBar.isHidden = false
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block:
        { (progressTimer) in
            
            if self.serverProgressBar.doubleValue < 90.0
            {
                self.serverProgressBar.increment(by: amount)
            }
            else
            {
                progressTimer.invalidate()
            }
        })
    }

    func stopIncrementingProgress()
    {
        serverProgressBar.doubleValue = 100
        sleep(1)
        serverProgressBar.isHidden = true
    }
    
    @IBAction func cancelLaunch(_ sender: NSButton)
    {
        killServer(sender)
    }
    
    @IBAction func killServer(_ sender: NSButton)
    {
        sender.isEnabled = false
        toggleConnectionButton.isEnabled = false
        launchServerButton.isEnabled = false
        startIncrementingProgress(by: 3.0)
        
//        MoonbounceViewController.terraformController.destroyTerraformServer
//        {
//            (destroyed) in
//
//            sender.isEnabled = true
//            self.toggleConnectionButton.isEnabled = true
//            self.launchServerButton.isEnabled = true
//            self.stopIncrementingProgress()
//            self.populateServerSelectButton()
//            self.showUserServerStatus()
//            appLog.debug("Destroy server task exited.")
//        }
    }
    
    @IBAction func closeTokenWindow(_ sender: NSButton)
    {
        self.accountTokenBox.isHidden = true
    }
    
    @IBAction func accountTokenEntered(_ sender: NSTextField)
    {
        //TODO: Sanity checks for input are needed here
        let newToken = sender.stringValue
        if newToken == ""
        {
            appLog.error("User entered an empty string for DO token")
            return
        }
        else
        {
            appLog.debug("New user token: \(newToken)")
            KeychainController.saveToken(token: sender.stringValue)
            hasDoToken = true
//            MoonbounceViewController.terraformController.createVarsFile(token: sender.stringValue)
        }
    }
    
    @IBAction func editToken(_ sender: NSButton)
    {
        accountTokenBox.isHidden = false
    }
    
    func connect()
    {        
        serverSelectButton.isEnabled = false
        runBackgroundAnimation()
        isConnected = ConnectState(state: .start, stage: .start)
        runningScript = true
        
        //Update button name
        self.toggleConnectionButton.title = "Disconnect"
        
        //serverManager.tunnelsManager?.startActivation(of: tunnel)
        
        // TODO: For now we are just loading a default config
        guard let moonbounceConfig = configController.getDefaultMoonbounceConfig()
        else
        {
            appLog.error("Unable to connect, unable to load default config.")
            self.runningScript = false
            self.serverSelectButton.isEnabled = true
            self.showStatus()
            return
        }
        
        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig, isEnabled: true)
        {
            (maybeLoadError) in
            
            if let loadError = maybeLoadError
            {
                appLog.error("Unable to connect, error loading from preferences: \(loadError)")
                self.runningScript = false
                self.serverSelectButton.isEnabled = true
                self.showStatus()
                return
            }
            
            guard let vpnPreference = VPNPreferencesController.shared.maybeVPNPreference
            else
            {
                appLog.error("Unable to connect, vpnPreference is nil.")
                self.runningScript = false
                self.serverSelectButton.isEnabled = true
                self.showStatus()
                return
            }
            
            let loggingController = LoggingController()
            
            if vpnPreference.connection.status == .disconnected || vpnPreference.connection.status == .invalid
            {
                appLog.debug("\nConnect pressed, starting logging loop.\n")
                loggingController.startLoggingLoop()
                
                do
                {
                    appLog.debug("\nCalling startVPNTunnel on vpnPreference.connection.\n")
                    try vpnPreference.connection.startVPNTunnel()
                }
                catch
                {
                    appLog.error("\nFailed to start the VPN: \(error.localizedDescription)\n")
                    loggingController.stopLoggingLoop()
                }
                
                //self.activityIndicator.stopAnimating()
            }
            else
            {
                loggingController.stopLoggingLoop()
                vpnPreference.connection.stopVPNTunnel()
            }
        }
        
        //Verify that connection was successful and update accordingly
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
//    func setSelectedServer(tunnel: Tunnel)
//    {
//        selectedTunnel = tunnel
//        checkForServerIP()
//    }
    
    func checkForServerIP()
    {
//        guard let tunnel = selectedTunnel
//            else
//        {
//            appLog.error("\nunable to find current server IP: current tunnel is not set.\n")
//            return
//        }
        guard let vpnPreferences = VPNPreferencesController.shared.maybeVPNPreference
        else
        {
            appLog.error("Unable to find a server IP, our vpnPreference is nil.")
            return
        }
        
        if let ipString = vpnPreferences.protocolConfiguration?.serverAddress//tunnel.targetManager.protocolConfiguration?.serverAddress
        {
            currentHost = NWEndpoint.Host(ipString)
            appLog.debug("Current Server host is: \(currentHost!)")
        }
    }
    
    func disconnect()
    {
//        guard let tunnel = selectedTunnel
//            else
//        {
//            appLog.error("Unable to find a tunnel to stop.")
//            return
//        }
        
        guard let vpnPreferences = VPNPreferencesController.shared.maybeVPNPreference
        else
        {
            appLog.error("Unable to find a server IP, our vpnPreference is nil.")
            return
        }
        
        vpnPreferences.connection.stopVPNTunnel()
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
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
    
    func populateServerSelectButton()
    {
        serverSelectButton.removeAllItems()
        
        /// We do not currently support launching servers
//
//        //Default server should always be an option as we provide this.
//        if let defaultServer = tunnelController.defaultTunnel
//        {
//            let defaultMenuItem = NSMenuItem(title: defaultTunnelName, action: nil, keyEquivalent: "")
//            defaultMenuItem.representedObject = defaultServer
//            self.serverSelectButton.menu?.addItem(defaultMenuItem)
//            self.setSelectedServer(tunnel: defaultServer)
//
//            //Don't make our default server available to share
//            self.shareServerButton.isHidden = true
//        }
//        else
//        {
//            appLog.error("\nDefault server not found.\n")
//        }
//
//        //We base availability of a given server on whether a config file in the correct directory exists.
//
//        // TODO: Check for user server
//        if let userServer = serverManager.userServer
//        {
//            self.userServerIsConnected = true
//            let menuItem = NSMenuItem(title: userServer.name, action: nil, keyEquivalent: "")
//            menuItem.representedObject = userServer
//            self.serverSelectButton.menu?.addItem(menuItem)
//
//            self.serverSelectButton.selectItem(withTitle: userServer.name)
//            self.shareServerButton.isHidden = false
//
//            //The user's server is default when available
//            self.setSelectedServer(tunnel: userServer)
//        }
//        else
//        {
//            self.userServerIsConnected = false
//        }
//
        //        // TODO: Check for imported servers
//        if !serverManager.importedServers.isEmpty
//        {
//            for importedServer in serverManager.importedServers
//            {
//                //Make a new menu item for our pop-up button for every config directory in the imported folder.
//
//                //Adding the new server info to our server select button.
//                let menuItem = NSMenuItem(title: importedServer.name, action: nil, keyEquivalent: "")
//                menuItem.representedObject = importedServer
//                self.serverSelectButton.menu?.addItem(menuItem)
//            }
//        }
    }

    func showUserServerStatus()
    {
        if userServerIsConnected
        {
            launchServerButton.title = "Shut Down Server"
            serverStatusLabel.stringValue = "Your server is currently running."
        }
        else
        {
            launchServerButton.title = "Launch Server"
            
            if launching
            {
                serverStatusLabel.stringValue = "Launching"
            }
            else
            {
                serverStatusLabel.stringValue = "Launch your own Moonbounce server."
            }
        }
    }

    func styleViews()
    {
        //Connection Button and label Styling
        showStatus()
        
        showUserServerStatus()
        
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
        
        //Has the user entered their Digital Ocean Token?
        //if let userToken = UserDefaults.standard.object(forKey: userTokenKey) as! String?
        if let userToken = KeychainController.loadToken()
        {
            if userToken == ""
            {
                hasDoToken = false
            }
            else
            {
                hasDoToken = true
                accountTokenTextField.stringValue = userToken
                appLog.debug("******Found a token in keychain!")
            }
        }
        else
        {
            hasDoToken = false
        }
    }
    
    func styleTokenTextField()
    {
        accountTokenTextField.wantsLayer = true
        let textFieldLayer = CALayer()
        accountTokenTextField.layer = textFieldLayer
        accountTokenTextField.backgroundColor = mbWhite
        accountTokenTextField.layer?.backgroundColor = mbWhite.cgColor
        accountTokenTextField.layer?.borderColor = (NSColor.clear).cgColor
        accountTokenTextField.layer?.borderWidth = 1
        accountTokenTextField.layer?.cornerRadius = 5
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
    
    @objc func animateLaunchingLabel()
    {
        if launching
        {
            if serverStatusLabel.stringValue == "Launching..."
            {
                serverStatusLabel.stringValue = "Launching"
            }
            else
            {
                serverStatusLabel.stringValue = "\(serverStatusLabel.stringValue)."
            }
            
            perform(#selector(animateLaunchingLabel), with: nil, afterDelay: 1)
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
