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

class MoonbounceViewController: NSViewController, NSSharingServicePickerDelegate, TunnelsManagerActivationDelegate
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
    
    var onTunnelsManagerReady: ((TunnelsManager) -> Void)?
    var tunnelsManager: TunnelsManager? = nil
    var userServerIsConnected = false
    var launching = false
    
    enum ServerName: String
    {
        case defaultServer = "Default Server"
        case userServer = "User Server"
        case importedServer = "Imported Server"
    }
    
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
        
        // Create the tunnels manager, and when it's ready, inform tunnelsListVC
        TunnelsManager.create
        {
            [weak self] result in
            
            guard let self = self else { return }
            
            if let error = result.error
            {
                //FIXME: Show error alert
                print("\nError creating tunnel manager: \(error)\n")
                //ErrorPresenter.showErrorAlert(error: error, from: self)
                return
            }
            
            let tunnelsManager: TunnelsManager = result.value!
            
            self.tunnelsManager = tunnelsManager
            
            tunnelsManager.activationDelegate = self
            
            self.onTunnelsManagerReady?(tunnelsManager)
            self.onTunnelsManagerReady = nil
        }
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
                if let configPath = menuItem.representedObject as? String
                {
                    setSelectedServer(atPath: configPath)
                    print("Setting selected server \(selectedItemTitle), with path:\n\(configPath)")
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
                    ServerController.sharedInstance.addServer(withConfigFileURL: chosenDirectory, presentInWindow: presentingWindow)
                }
                
                self.populateServerSelectButton()
            }
        }
    }
    
    //Button that allows users to save the current config directory to a directory of their choice in order to share it.
    @IBAction func shareServerClick(_ sender: NSButton)
    {
        //make sure we have a config directory, and that it is not the default server config directory
        if currentConfigDirectory != "" && currentConfigDirectory != defaultConfigDirectory
        {
            if let presentingWindow = self.view.window
            {
                sender.isEnabled = false
                serverSelectButton.isEnabled = false
                
                let currentServerName = URL(fileURLWithPath: currentConfigDirectory).lastPathComponent
                var serverName = currentServerName
                
                let alert = ServerController.sharedInstance.createServerNameAlert(defaultName: currentServerName)
                alert.beginSheetModal(for: presentingWindow, completionHandler:
                {
                    (response) in
                    
                    if response == NSApplication.ModalResponse.alertFirstButtonReturn, let textField = alert.accessoryView as? NSTextField
                    {
                        serverName = textField.stringValue
                    }
                    
//                    let zipPath = appDirectory.appending("/\(serverName).\(moonbounceExtension)")
                    
//                    //Zip the files and save to the temp directory.
//                    do
//                    {
//                        try Zip.zipFiles(paths: [URL(fileURLWithPath: currentConfigDirectory)], zipFilePath: URL(fileURLWithPath: zipPath), password: nil, progress:
//                        {
//                            (progress) in
//
//                            print(progress)
//                        })
//
//                        //Set up a sharing services picker
//                        let sharePicker = NSSharingServicePicker.init(items: [URL(fileURLWithPath: zipPath)])
//
//                        sharePicker.delegate = self
//                        sharePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
//                    }
//                    catch
//                    {
//                        print("Unable to zip config directory for export!")
//                    }
                    
                    sender.isEnabled = true
                    self.serverSelectButton.isEnabled = true
                })
            }
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
    
    
    //MARK: WireGuard
    
    func tunnelActivationAttemptFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationAttemptError)
    {
        print("\nTunnel Activation Attempt Failed: \(error)\n")
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
    func tunnelActivationAttemptSucceeded(tunnel: TunnelContainer)
    {
        print("\nTunnel Activation Attempt Succeeded\n")
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
    func tunnelActivationFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationError)
    {
        print("\nTunnel Activation Failed: \(error)\n")
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
    func tunnelActivationSucceeded(tunnel: TunnelContainer)
    {
        print("\nTunnel Activation Succeeded\n")
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
        self.showStatus()
    }
    
    func connect()
    {
        serverSelectButton.isEnabled = false
        runBackgroundAnimation()
        isConnected = ConnectState(state: .start, stage: .start)
        runningScript = true
        
        //Update button name
        self.toggleConnectionButton.title = "Disconnect"

        
        
        /// WireGuard Tunnel Manager
        guard let tunnel = tunnelsManager?.tunnel(at: 0)
        else
        {
            print("Unable to find a tunnel to start.")
            return
        }
        tunnelsManager?.startActivation(of: tunnel)
        
        /// Replicant
        
        //TODO: Config File Path Based on User Input
        guard let replicantConfig = ReplicantConfig(withConfigAtPath: currentConfigDirectory)
        else
        {
            print("\nUnable to parse Replicant config file.\n")
            return
        }
        
        //TODO: Replicant Server IP & Port

        guard let replicantPort = NWEndpoint.Port(rawValue: 51820)
        else
        {
            print("\nUnable to generate port for replicant connection.\n")
            return
        }
        
        let replicantServerIP = NWEndpoint.Host(currentServerIP)
        
        let replicantConnectionFactory = ReplicantConnectionFactory(host: replicantServerIP, port: replicantPort, config: replicantConfig)
        guard let replicantConnection = replicantConnectionFactory.connect(using: .tcp)
        else
        {
            print("Unable to establish a Replicant connection.")
            return
        }
        
        
//        MoonbounceViewController.shiftedOpenVpnController.start(configFilePath: currentConfigDirectory, completion:
//        {
//            (didLaunch) in
//
//            //Go back to the main thread
//            DispatchQueue.main.async(execute:
//            {
//                //You can safely do UI stuff here
//                //Verify that connection was succesful and update accordingly
//                self.runningScript = false
//                self.serverSelectButton.isEnabled = true
//                self.showStatus()
//            })
//        })
    }
    
    func setSelectedServer(atPath configPath: String)
    {
        currentConfigDirectory = configPath
        checkForServerIP()
    }
    
    func checkForServerIP()
    {
        //Get the file that has the server IP
        if currentConfigDirectory != ""
        {
            //TODO: This will need to point to something different based on what config files are being used
            let ipFileDirectory = currentConfigDirectory.appending("/" + ipFileName)
            
            do
            {
                let ip = try String(contentsOfFile: ipFileDirectory, encoding: String.Encoding.ascii)
                currentServerIP = ip
                
                print("Current Server IP is: \(ip)")
            }
            catch
            {
                print("Unable to locate the server IP at: \(ipFileDirectory).")
            }
        }
    }
    
    func disconnect()
    {
//        MoonbounceViewController.shiftedOpenVpnController.stop(completion:
//        {
//            (stopped) in
//            //
//
//        })
        
        guard let tunnel = tunnelsManager?.tunnel(at: 0)
            else
        {
            print("Unable to find a tunnel to stop.")
            return
        }
        
        tunnelsManager?.startDeactivation(of: tunnel)
        self.runningScript = false
        self.serverSelectButton.isEnabled = true
    }
    
    //MARK: UI Helpers
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
        
        //Default server should always be an option as we provide this.
        let defaultMenuItem = NSMenuItem(title: ServerName.defaultServer.rawValue, action: nil, keyEquivalent: "")
        defaultMenuItem.representedObject = defaultConfigDirectory
        serverSelectButton.menu?.addItem(defaultMenuItem)

        //We base availability of a given server on whether a file with the IP address exists.
        if userServerIP == ""
        {
            userServerIsConnected = false
            serverSelectButton.selectItem(withTitle: ServerName.defaultServer.rawValue)
            
            //Set our server as default if user server is not available.
            setSelectedServer(atPath: defaultConfigDirectory)
            
            //Don't make our default server available to share
            shareServerButton.isHidden = true
        }
        else
        {
            //If we can find a user server IP then the user's server should also be listed.
            userServerIsConnected = true
            //serverSelectButton.addItem(withTitle: ServerName.userServer.rawValue)
            let menuItem = NSMenuItem(title: ServerName.userServer.rawValue, action: nil, keyEquivalent: "")
            menuItem.representedObject = userConfigDirectory
            serverSelectButton.menu?.addItem(menuItem)
            serverSelectButton.selectItem(withTitle: ServerName.userServer.rawValue)
            
            shareServerButton.isHidden = false
            
            //The user's server is default when available
            setSelectedServer(atPath: userConfigDirectory)
        }
        
        //Check to see if we have an Imported Config Files Directory Path
        if importedConfigDirectory != ""
        {
            //Check for sub-directories in the Imported folder
            let importDirectoryURL = URL(fileURLWithPath: importedConfigDirectory)
            let subDirectories = (try? FileManager.default.contentsOfDirectory(at: importDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.hasDirectoryPath }) ?? [URL]()
            
            if !subDirectories.isEmpty
            {
                //Make a new menu item for our pop-up button for every config directory in the imported folder.
                for configDirectory in subDirectories
                {
                    let ipFilePath = configDirectory.path.appending("/serverIP")
                    do
                    {
                        //Make sure the ip file is there before we bother to add it to the list
                        _ = try String(contentsOfFile: ipFilePath, encoding: String.Encoding.ascii)
                        
                        //Adding the new server info to our server select button.
                        let menuItem = NSMenuItem(title: configDirectory.lastPathComponent, action: nil, keyEquivalent: "")
                        menuItem.representedObject = configDirectory.path
                        serverSelectButton.menu?.addItem(menuItem)
                    }
                    catch
                    {
                        print("Unable to locate the imported server IP at: \(ipFilePath).\nServer will not be added to the list of possible servers.)")
                    }
                }
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
