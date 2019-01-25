//
//  ServerController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 9/1/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Cocoa
import ZIPFoundation
import ReplicantSwift

class ServerController: NSObject, TunnelsManagerActivationDelegate
{
    var importedServers = [TunnelContainer]()
    var userServer: TunnelContainer?
    var defaultServer: TunnelContainer?
    var currentTunnel: TunnelContainer?
    
    var onTunnelsManagerReady: ((TunnelsManager) -> Void)?
    var tunnelsManager: TunnelsManager? = nil
    
    override init()
    {
        super.init()
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
    
    func refreshServers()
    {
        // Default Server
        addServerToTunnels(name: ServerName.defaultServer.rawValue, configDirectory: defaultConfigDirectory)
        {
            (result) in
            
            switch result
            {
            case .failure(let error):
                print("\nFailed to add default server to tunnels: \(error)\n")
            case .success(let container):
                self.defaultServer = container
            }
        }
        
        // User Server
        addServerToTunnels(name: ServerName.userServer.rawValue, configDirectory: userConfigDirectory)
        {
            (result) in
            switch result
            {
            case .failure(let error):
                print("\nNo user server found: \(error)\n")
            case .success(let container):
                self.userServer = container
            }
        }
        
        // Imported Servers
        let subDirectories = (try? FileManager.default.contentsOfDirectory(at: importedConfigDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.hasDirectoryPath }) ?? [URL]()
        
        if !subDirectories.isEmpty
        {
            for configDirectory in subDirectories
            {
                let importedServerName = FileManager.default.displayName(atPath: configDirectory.path)
                addServerToTunnels(name: importedServerName, configDirectory: configDirectory)
                {
                    (result) in
                    
                    switch result
                    {
                    case .failure(let error):
                        print("\nFailed to add imported server at \(configDirectory)\nError:\(error)\n")
                    case .success(let container):
                        self.importedServers.append(container)
                    }
                }
            }
        }
    }
    
    // MARK: - Tunnels
    
    func tunnelActivationAttemptFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationAttemptError)
    {
        print("\nTunnel Activation Attempt Failed: \(error)\n")
    }
    
    func tunnelActivationAttemptSucceeded(tunnel: TunnelContainer)
    {
        print("\nTunnel Activation Attempt Succeeded\n")
    }
    
    func tunnelActivationFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationError)
    {
        print("\nTunnel Activation Failed: \(error)\n")
    }
    
    func tunnelActivationSucceeded(tunnel: TunnelContainer)
    {
        print("\nTunnel Activation Succeeded\n")
    }
    
    func addServerToTunnels(name: String, configDirectory: URL, completionHandler: @escaping (WireGuardResult<TunnelContainer>) -> Void)
    {
        let clientConfigDirectory = configDirectory.appendingPathComponent(clientConfigFileName, isDirectory: false)
        if let clientConfig = ClientConfig(withConfigAtPath: clientConfigDirectory.path)
        {
            let replicantConfigDirectory = configDirectory.appendingPathComponent(replicantConfigFileName, isDirectory: false)
            let replicantConfig = ReplicantConfig(withConfigAtPath: replicantConfigDirectory.path)
            let tunnelConfiguration = TunnelConfiguration(name: name, clientConfig: clientConfig, replicantConfig: replicantConfig, directory: configDirectory)
            tunnelsManager?.add(tunnelConfiguration: tunnelConfiguration, completionHandler:
            {
                (result) in
                
                completionHandler(result)
            })
        }
        else
        {
            completionHandler(WireGuardResult.failure(TunnelsManagerError.errorOnListingTunnels))
        }
    }
    
    // Mark: - User added servers
    func addServer(withConfigFilePath configPath: String)
    {
        let configFileURL = URL(fileURLWithPath: configPath, isDirectory: false)
        
        addServer(withConfigFileURL: configFileURL)
    }
    
    func addServer(withConfigFileURL configURL: URL)
    {
        addServer(withConfigFileURL: configURL, presentInWindow: nil)
    }
    
    func addServer(withConfigFileURL configURL: URL, presentInWindow currentWindow: NSWindow?)
    {
        let fileManager = FileManager()
        let newImportConfigName = fileManager.displayName(atPath: configURL.path)
        var newImportConfigDirectory = importedConfigDirectory.appendingPathComponent(newImportConfigName, isDirectory: true)
        
        let alert = createServerNameAlert(defaultName: newImportConfigName)
    
        if currentWindow == nil
        {
            let response: NSApplication.ModalResponse = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn
            {
                if let textField = alert.accessoryView as? NSTextField
                {
                    let selectedName = textField.stringValue
                    if selectedName != ""
                    {
                        //Rename Config Directory to User Selected Name
                        newImportConfigDirectory = importedConfigDirectory.appendingPathComponent(selectedName, isDirectory: true)
                        let fileManager = FileManager.default
                        
                        //Unzip the selected file
                        do
                        {
                            try fileManager.unzipItem(at: configURL, to: importedConfigDirectory)
                            print("Unzipped to :\(importedConfigDirectory)")
                        }
                        catch (let error)
                        {
                            print("\nFailed to unzip config files: \(error)\n")
                            return
                        }
                    }
                }
            }
        }
        else
        {
            alert.beginSheetModal(for: currentWindow!, completionHandler:
            { (response) in
                
                if response == NSApplication.ModalResponse.alertFirstButtonReturn, let textField = alert.accessoryView as? NSTextField
                {
                    let selectedName = textField.stringValue
                    if selectedName != ""
                    {
                        //Rename Config Directory to User Selected Name
                        newImportConfigDirectory = importedConfigDirectory.appendingPathComponent(selectedName, isDirectory: true)
                        
                        //Unzip the selected file
                        do
                        {
                            try fileManager.unzipItem(at: configURL, to: importedConfigDirectory)
                            print("Unzipped to :\(importedConfigDirectory)")
                        }
                        catch (let error)
                        {
                            print("\nFailed to unzip config files: \(error)\n")
                            return
                        }
                    }
                }
            })
        }
        
        if configFilesAreValid(atURL: newImportConfigDirectory)
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNewServerAddedNotification) , object: nil)
        }
    }
    
    func configFilesAreValid(atURL configURL: URL) -> Bool
    {
        do
        {
            let fileManager = FileManager.default
            if let fileEnumerator = fileManager.enumerator(at: configURL, includingPropertiesForKeys: [.nameKey], options: [.skipsHiddenFiles], errorHandler:
                {
                    (url, error) -> Bool in
                    
                    print("File enumerator error at \(configURL.path): \(error.localizedDescription)")
                    return true
            })
            {
                //Verify  that each of the following files are present as all config files are neccessary for successful connection:
                let file1 = "replicant.config"
                let file2 = "client.config"
                
                var fileNames = [String]()
                for case let fileURL as URL in fileEnumerator
                {
                    let fileName = try fileURL.resourceValues(forKeys: Set([.nameKey]))
                    if fileName.name != nil
                    {
                        fileNames.append(fileName.name!)
                    }
                }
                
                //If all required files are present refresh server select button
                if fileNames.contains(file1) && fileNames.contains(file2)
                {
                    return true
                }
            }
        }
        catch
        {
            return false
        }
        
        return false
    }
    
    func createServerNameAlert(defaultName: String) -> NSAlert
    {
        let alert = NSAlert()
        alert.messageText = "Server Name"
        alert.informativeText = "Please name this server."
        alert.addButton(withTitle: "OK") //1st Button
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = defaultName
        textField.placeholderString = "Server Name"
        alert.accessoryView = textField
        
        return alert
    }

}

enum ServerName: String
{
    case defaultServer = "Default"
    case userServer = "User"
    case importedServer = "Imported"
}
