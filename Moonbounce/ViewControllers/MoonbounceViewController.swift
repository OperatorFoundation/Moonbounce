//
//  MoonbounceViewController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 10/24/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Cocoa
import SwiftyOpenVPNClient

class MoonbounceViewController: NSViewController
{
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var advancedModeButton: NSButton!
    @IBOutlet weak var toggleConnectionButton: NSButton!
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var laserImageView: NSImageView!
    @IBOutlet weak var laserLeadingConstraint: NSLayoutConstraint!
    
    dynamic var runningScript = false
    static var openVPN:OpenVPN?
    {
        get
        {
            guard let path = Bundle.main.path(forResource: "openvpn", ofType: nil)
                else
            {
                print("Could not find openVPN executable. wtf D:")
                return nil
            }
            
            return OpenVPN(pathToOVPNExecutable: path)
        }
    }
    
    //Advanced Mode Outlets
    @IBOutlet weak var advancedModeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ipAddressField: NSTextField!
    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var tpParametersField: NSTextField!
    @IBOutlet weak var tpTypeSelectionButton: NSPopUpButton!
    @IBOutlet var outputView: NSTextView!
    
    let proximaNARegular = "Proxima Nova Alt Regular"
    let advancedMenuHeight: CGFloat = 250.0
    var isConnected = false
    {
        didSet
        {
            if isConnected
            {
                showConnectedStatus()
            }
            else
            {
                showDisconnectedStatus()
            }
        }
    }
    
    //MARK: View Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Listen for Bash output
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kOutputTextNotification), object: nil, queue: nil, using: showProcessOutputInTextView)
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        styleViews()
    }
    
    //MARK: Action!
    @IBAction func toggleConnection(_ sender: NSButton)
    {
        if isConnected
        {
            self.disconnect()
        }
        else
        {
            self.connect()
        }
    }
    
    @IBAction func showAdvancedMode(_ sender: AnyObject)
    {
        if advancedModeHeightConstraint.constant > 0
        {
            closeMenu(sender: sender)
        }
        else
        {
            showMenu(sender: sender)
        }
    }
    
    //MARK: OVPN
    func connect()
    {
        outputView.string = ""
        runBackgroundAnimation()
        statusLabel.stringValue = "Connecting"
        
        if MoonbounceViewController.openVPN != nil
        {
            MoonbounceViewController.openVPN?.start(completion: { (isConnected) in
                //Go back to the main thread
                DispatchQueue.main.async(execute:
                    {
                        //You can safely do UI stuff here
                        //Verify that connection was succesful and update accordingly
                        self.isConnected = isConnected
                })
            })
        }
            
        else
        {
            print("Unable to locate openVPN")
            self.isConnected = false
            return
        }
    }
    
    func disconnect()
    {
        isConnected = false
    }
    
    //Dev purposes - Show output from command line task
    func showProcessOutputInTextView(notification: Notification) -> Void
    {
        guard let userInfo = notification.userInfo, let outputString = userInfo[outputStringKey] as? String
        else
        {
            print("No userInfo found in notification")
            return
        }
        
        let previousOutput = self.outputView.string ?? ""
        let nextOutput = previousOutput + "\n" + outputString
        self.outputView.string = nextOutput
        
        //Scroll the textview so that newest lines are visible
        let range = NSRange(location: nextOutput.characters.count, length: 0)
        self.outputView.scrollRangeToVisible(range)
    }
    
    //MARK: UI Helpers
    func styleViews()
    {
        //Title Label Styling
        if let titleFont = NSFont(name: proximaNARegular, size: 34)
        {
            let titleLabelAttributes = [NSKernAttributeName: 7.8,
                                        NSFontAttributeName: titleFont] as [String : Any]
            titleLabel.attributedStringValue = NSAttributedString(string: "MOONBOUNCE VPN", attributes: titleLabelAttributes)
        }
        
        //Connection Button Styling
        if let connectButtonFont = NSFont(name: proximaNARegular, size: 13)
        {
            let connectButtonAttributes = [NSForegroundColorAttributeName: NSColor.white,
                                           NSFontAttributeName: connectButtonFont]
            toggleConnectionButton.attributedTitle = NSAttributedString(string: "Connect", attributes: connectButtonAttributes)
            //toggleConnectionButton.attributedAlternateTitle = NSAttributedString(string: "Disconnect", attributes: connectButtonAttributes)
        }
        //Connect Button Border
        toggleConnectionButton.layer?.backgroundColor = .clear
        toggleConnectionButton.layer?.borderColor = .white
        toggleConnectionButton.layer?.borderWidth = 2
        toggleConnectionButton.layer?.cornerRadius = 10
        
        //Advanced Mode Button
        if let menuButtonFont = NSFont(name: proximaNARegular, size: 18)
        {
            let menuButtonAttributes = [NSForegroundColorAttributeName: NSColor.white,
                                        NSFontAttributeName: menuButtonFont]
            advancedModeButton.attributedTitle = NSAttributedString(string: "Advanced Mode", attributes: menuButtonAttributes)
        }
        advancedModeButton.layer?.backgroundColor = .clear
        
        //Advanced Mode Box
        advancedModeHeightConstraint.constant = 0
    }
    
    func showMenu(sender: AnyObject?)
    {
        advancedModeHeightConstraint.constant = advancedMenuHeight
    }
    
    func closeMenu(sender: AnyObject?)
    {
        advancedModeHeightConstraint.constant = 0
    }
    
    func runBackgroundAnimation()
    {
        NSAnimationContext.runAnimationGroup(
            {
                (context) in
                context.duration = 0.75
                self.laserLeadingConstraint.animator().constant = 260
        },completionHandler:
            {
                NSAnimationContext.runAnimationGroup(
                    { (context) in
                        context.duration = 0.75
                        self.laserLeadingConstraint.animator().constant = -5
                },completionHandler:
                    {
                        if self.runningScript == true
                        {
                            self.runBackgroundAnimation()
                        }
                })
        })
    }
    
    func showConnectedStatus()
    {
        //Update Connection Status Label
        self.statusLabel.stringValue = "Connected"
        
        //Update button name
        if let connectButtonFont = NSFont(name: self.proximaNARegular, size: 13)
        {
            let connectButtonAttributes = [NSForegroundColorAttributeName: NSColor.white,
                                           NSFontAttributeName: connectButtonFont]
            self.toggleConnectionButton.attributedTitle = NSAttributedString(string: "Disconnect", attributes: connectButtonAttributes)
        }
        
        //Stop BG Animation
        self.runningScript = false
    }
    
    func showDisconnectedStatus()
    {
        //Update Connection Status Label
        self.statusLabel.stringValue = "Disconnected"
        
        //Update button name
        if let connectButtonFont = NSFont(name: self.proximaNARegular, size: 13)
        {
            let connectButtonAttributes = [NSForegroundColorAttributeName: NSColor.white,
                                           NSFontAttributeName: connectButtonFont]
            self.toggleConnectionButton.attributedTitle = NSAttributedString(string: "Connect", attributes: connectButtonAttributes)
        }
        
        //Stop BG Animation
        self.runningScript = false
    }
    
}
