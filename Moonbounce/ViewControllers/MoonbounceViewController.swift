//
//  MoonbounceViewController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import Replicant
import ReplicantSwift
import Network

class MoonbounceViewController: NSViewController, NSSharingServicePickerDelegate
{
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var advancedModeButton: NSButton!
    @IBOutlet weak var toggleConnectionButton: CustomButton!
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var laserImageView: NSImageView!
    @IBOutlet weak var laserLeadingConstraint: NSLayoutConstraint!

    @objc dynamic var runningScript = false
    static var terraformController = TerraformController()
    
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
    
    
    var userServerIsConnected = false
    var launching = false
    
    //MARK: View Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: NSNotification.Name(rawValue: kConnectionStatusNotification), object: nil, queue: nil, using: connectionStatusChanged)
        nc.addObserver(forName: NSNotification.Name(rawValue: kNewServerAddedNotification), object: nil, queue: nil, using: newServerAdded)
        
        serverProgressBar.usesThreadedAnimation = true
        updateStatusUI(connected: false, statusDescription: "Not Connected")
        populateServerSelectButton()
        styleTokenTextField()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        styleViews()
    }
    
    func connectionStatusChanged(notification: Notification)
    {
        showStatus()
    }
    
    func newServerAdded(notification: Notification)
    {
        populateServerSelectButton()
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
                    self.connect()
                default:
                    print("Error: Connected state of Start but Stage is \(isConnected.stage)")
                }
            case .trying:
                switch isConnected.stage
                {
                    case .start:
                        //Should Not Happen
                        print("Error: Connected state of Trying but Stage is Start")
                    default:
                        //Terminate Dispatcher Task & Kill OpenVPN & Management
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
            if selectedItemTitle == ServerName.defaultServer.rawValue
            {
                shareServerButton.isHidden = true
            }
            else
            {
                shareServerButton.isHidden = false
            }
            
            if let menuItem =  sender.menu?.item(withTitle: selectedItemTitle)
            {
                if let tunnel = menuItem.representedObject as? TunnelContainer
                {
                    setSelectedServer(tunnel: tunnel)
                    print("Setting selected server \(selectedItemTitle)")
                }
            }
        }
        else
        {
            print("Unable to understand server selection, we could not get an item title from the popup button.")
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
                    serverManager.addServer(withConfigFileURL: chosenDirectory, presentInWindow: presentingWindow)
                }
                
                self.populateServerSelectButton()
            }
        }
    }
    
    //Button that allows users to save the current config directory to a directory of their choice in order to share it.
    @IBAction func shareServerClick(_ sender: NSButton)
    {
        //make sure we have a config directory, and that it is not the default server config directory
        guard let tunnel = serverManager.currentTunnel
            else
        {
            print("\nUnable to share server. Current server not found.\n")
            return
        }
        
        guard tunnel.name != ServerName.defaultServer.rawValue
        else
        {
            print("\nAttempted to share default server...\n")
            return
        }
        
        guard let configURL = tunnel.tunnelConfiguration?.directory
        else
        {
            print("\nUnable to share server config, the directory URL is unknown.\n")
            return
        }

        if let presentingWindow = self.view.window
        {
            sender.isEnabled = false
            serverSelectButton.isEnabled = false
            
            var serverName = tunnel.name
            
            let alert = serverManager.createServerNameAlert(defaultName: serverName)
            alert.beginSheetModal(for: presentingWindow, completionHandler:
            {
                (response) in
                
                if response == NSApplication.ModalResponse.alertFirstButtonReturn, let textField = alert.accessoryView as? NSTextField
                {
                    serverName = textField.stringValue
                }
                
                var zipPath = moonbounceDirectory.appendingPathComponent(serverName, isDirectory: false)
                zipPath = zipPath.appendingPathExtension(moonbounceExtension)
                
                //Zip the files and save to the temp directory.
                do
                {
                    try FileManager.default.zipItem(at: configURL, to: zipPath)

                    //Set up a sharing services picker
                    let sharePicker = NSSharingServicePicker.init(items: [zipPath])

                    sharePicker.delegate = self
                    sharePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
                }
                catch
                {
                    print("\nUnable to zip config directory for export!\n")
                }
                
                sender.isEnabled = true
                self.serverSelectButton.isEnabled = true
            })
        }
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService]
    {
//        if proposedServices.contains(NSSharingService(named: NSSharingServiceName))
//        {
//            
//        }
        print("Share services: \(proposedServices)")
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
        if let userToken = KeychainController.loadToken()
        {
            MoonbounceViewController.terraformController.createVarsFile(token: userToken)
            
            sender.isEnabled = false
            toggleConnectionButton.isEnabled = false
            startIncrementingProgress(by: 0.5)
            cancelLaunchButton.isHidden = false
            serverStatusLabel.stringValue = "Launching"
            launching = true
            animateLaunchingLabel()
            
            MoonbounceViewController.terraformController.launchTerraformServer
            {
                (launched) in
                
                sender.isEnabled = true
                self.toggleConnectionButton.isEnabled = true
                self.stopIncrementingProgress()
                self.populateServerSelectButton()
                self.showUserServerStatus()
                
                print("Launch server task exited.")
                self.cancelLaunchButton.isHidden = true
                self.launching = false
            }
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
        
        MoonbounceViewController.terraformController.destroyTerraformServer
        {
            (destroyed) in
            
            sender.isEnabled = true
            self.toggleConnectionButton.isEnabled = true
            self.launchServerButton.isEnabled = true
            self.stopIncrementingProgress()
            self.populateServerSelectButton()
            self.showUserServerStatus()
            print("Destroy server task exited.")
        }
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
            print("User entered an empty string for DO token")
            return
        }
        else
        {
            print("New user token: \(newToken)")
            KeychainController.saveToken(token: sender.stringValue)
            hasDoToken = true
            MoonbounceViewController.terraformController.createVarsFile(token: sender.stringValue)
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

        guard let tunnel = serverManager.currentTunnel
        else
        {
            print("Unable to find a tunnel to start.")
            //Verify that connection was succesful and update accordingly
            self.runningScript = false
            self.serverSelectButton.isEnabled = true
            self.showStatus()
            return
        }
        
        serverManager.tunnelsManager?.startActivation(of: tunnel)
        
        //Verify that connection was succesful and update accordingly
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
    func setSelectedServer(tunnel: TunnelContainer)
    {
        serverManager.currentTunnel = tunnel
        checkForServerIP()
    }
    
    func checkForServerIP()
    {
        guard let tunnel = serverManager.currentTunnel
            else
        {
            print("\nunable to find current server IP: current tunnel is not set.\n")
            return
        }
        
        guard let clientConfig = tunnel.tunnelConfiguration?.clientConfig
        else
        {
            return
        }
        
        currentHost = clientConfig.host
        print("Current Server host is: \(currentHost!)")
    }
    
    func disconnect()
    {
        guard let tunnel = serverManager.currentTunnel
            else
        {
            print("Unable to find a tunnel to stop.")
            return
        }
        
        serverManager.tunnelsManager?.startDeactivation(of: tunnel)
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
    }
    
    // MARK: - UI Helpers
    // TODO: Wire this to tunnels
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
                print("Error: Connected state of Start but Stage is \(isConnected.stage)")
            }
        case .trying:
            switch isConnected.stage
            {
                case .start:
                    //Should Not Happen
                    print("Error: Connected state of Trying but Stage is Start")
                case .dispatcher:
                    self.updateStatusUI(connected: true, statusDescription: "Starting Dispatcher")
                case .openVpn:
                    self.updateStatusUI(connected: true, statusDescription: "Launching OpenVPN")
                case .management:
                    self.updateStatusUI(connected: true, statusDescription: "Connecting to the Management Server")
                case .statusCodes:
                    self.updateStatusUI(connected: true, statusDescription: "Getting OpenVPN Status")
            }
        case .success:
            switch isConnected.stage
            {
            case .start:
                //Should Not Happen
                print("Error: Connected state of Success but Stage is Start")
            case .dispatcher:
                self.updateStatusUI(connected: true, statusDescription: "Started Dispatcher")
            case .openVpn:
                self.updateStatusUI(connected: true, statusDescription: "Launched OpenVPN")
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
                print("Error: Connected state of Failed but Stage is Start")
            case .dispatcher:
                self.updateStatusUI(connected: false, statusDescription: "Failed to start Dispatcher")
            case .openVpn:
                self.updateStatusUI(connected: false, statusDescription: "Failed to launch OpenVPN")
            case .management:
                self.updateStatusUI(connected: false, statusDescription: "Failed to Connect to the Management Server")
            case .statusCodes:
                self.updateStatusUI(connected: false, statusDescription: "Failed to connect  to OpenVPN")
            }
        }
    }
    
    func populateServerSelectButton()
    {
        serverSelectButton.removeAllItems()
        
        // TODO: Address possible race condition
        serverManager.refreshServers()
        
        //Default server should always be an option as we provide this.
        if let defaultServer = serverManager.defaultServer
        {
            let defaultMenuItem = NSMenuItem(title: defaultServer.name, action: nil, keyEquivalent: "")
            defaultMenuItem.representedObject = defaultServer
            self.serverSelectButton.menu?.addItem(defaultMenuItem)
            setSelectedServer(tunnel: defaultServer)
            
            //Don't make our default server available to share
            shareServerButton.isHidden = true
        }
        else
        {
            print("\nDefault server not found.\n")
        }
        
        //We base availability of a given server on whether a config file in the correct directory exists.
        
        // Check for user server
        if let userServer = serverManager.userServer
        {
            userServerIsConnected = true
            let menuItem = NSMenuItem(title: userServer.name, action: nil, keyEquivalent: "")
            menuItem.representedObject = userServer
            serverSelectButton.menu?.addItem(menuItem)
            
            serverSelectButton.selectItem(withTitle: userServer.name)
            shareServerButton.isHidden = false
            
            //The user's server is default when available
            setSelectedServer(tunnel: userServer)
        }
        else
        {
            userServerIsConnected = false
        }

        //Check for imported servers
        if !serverManager.importedServers.isEmpty
        {
            for importedServer in serverManager.importedServers
            {
                //Make a new menu item for our pop-up button for every config directory in the imported folder.
                
                //Adding the new server info to our server select button.
                let menuItem = NSMenuItem(title: importedServer.name, action: nil, keyEquivalent: "")
                menuItem.representedObject = importedServer
                serverSelectButton.menu?.addItem(menuItem)
            }
        }
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
                print("******Found a token in keychain!")
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
    
    //Helper for showing an alert.
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
}
