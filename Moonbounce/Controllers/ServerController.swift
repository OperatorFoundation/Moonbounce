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
        do
        {
            //Make sure zip recognizes our custom file extension
//            Zip.addCustomFileExtension(moonbounceExtension)
//            Zip.addCustomFileExtension("MOONBOUNCE")
            
            //Unzip the selected file
//            try Zip.unzipFile(configURL, destination: URL(fileURLWithPath: importedConfigDirectory), overwrite: true, password: nil, progress:
//            {
//                (progress) in
//                
//                print(progress)
//            })
            
            print("Unzipped to :\(importedConfigDirectory)")
            let defaultName = configURL.deletingPathExtension().lastPathComponent
            let defaultConfigDirectory = importedConfigDirectory + "/" + defaultName
            let defaultConfigURL = URL(fileURLWithPath: defaultConfigDirectory, isDirectory: true)
            if configFilesAreValid(atURL: defaultConfigURL)
            {
                let alert = createServerNameAlert(defaultName: defaultName)
                
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
                                let newConfigDirectory = importedConfigDirectory + "/" + selectedName
                                let fileManager = FileManager.default
                                
                                do
                                {
                                    try fileManager.moveItem(atPath: defaultConfigDirectory, toPath: newConfigDirectory)
                                }
                                catch
                                {
                                    print("Error renaming new config directory: \(error.localizedDescription)")
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
                                let newConfigDirectory = importedConfigDirectory + "/" + selectedName
                                let fileManager = FileManager.default
                                
                                do
                                {
                                    try fileManager.moveItem(atPath: defaultConfigDirectory, toPath: newConfigDirectory)
                                }
                                catch
                                {
                                    print("Error renaming new config directory: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNewServerAddedNotification) , object: nil)
                    })
                }
            }
        }
        catch
        {
            print("Unable to unzip file at path: \(configURL.path)")
            print("Error: \(error)")
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
                let file1 = "ca.crt"
                let file2 = "client1.crt"
                let file3 = "client1.key"
                let file4 = "DO.ovpn"
                let file5 = "server.crt"
                let file6 = "serverIP"
                let file7 = "ta.key"
                
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
                if fileNames.contains(file1) && fileNames.contains(file2) && fileNames.contains(file3) && fileNames.contains(file4) && fileNames.contains(file5) && fileNames.contains(file6) && fileNames.contains(file7)
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
