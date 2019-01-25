//
//  ServerController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 9/1/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Cocoa
import ZIPFoundation

class ServerController: NSObject
{
    static let sharedInstance = ServerController()
    
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
