//
//  MoonbounceTests.swift
//  MoonbounceTests
//
//  Created by Adelita Schule on 1/10/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import XCTest
import Network
import ReplicantSwift
import Replicant
import Datable
import ZIPFoundation
@testable import Moonbounce

class MoonbounceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testVPNPreferencesUpdate()
    {
        let completionExpectation = expectation(description: "completion handler called")
        let configController = ConfigController()
        
        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
        else
        {
            print("Update test failed: unable to load default config.")
            XCTFail()
            return
        }
        
        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig)
        {
            (maybeError) in
            
            if let error = maybeError
            {
                print("Error testing update: \(error.localizedDescription)")
                XCTFail()
            }
            
            completionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testVPNPreferencesSetup()
    {
        let completionExpectation = expectation(description: "completion handler called")
        let configController = ConfigController()
        
        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
        else
        {
            print("Update test failed: unable to load default config.")
            XCTFail()
            return
        }
        
        VPNPreferencesController.shared.setup(moonbounceConfig: moonbounceConfig)
        {
            (managerOrError) in
            
            switch managerOrError
            {
            case .error(let error):
                print("Error testing VPNPreferences setup: \(error.localizedDescription)")
                XCTAssertNil(error)
            case .value(let manager):
                print("Setup test created a manager: \(manager.debugDescription)")
            }
            
            completionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testVPNPreferencesDeactivate()
    {
        let completionExpectation = expectation(description: "completion handler called")
               
               VPNPreferencesController.shared.deactivate
               {
                   (maybeError) in
                   
                   if let error = maybeError
                   {
                       print("Error testing activate: \(error.localizedDescription)")
                       XCTFail()
                   }
                   
                   completionExpectation.fulfill()
               }
               
               waitForExpectations(timeout: 1, handler: nil)
    }

//    func testCreateConfigs()
//    {
//        let fileManager = FileManager.default
//        guard let applicationDirectoryURL = getApplicationDirectory()
//        else
//        {
//            XCTFail()
//            return
//        }
//        
//        let moonbounceConfigDirectory = applicationDirectoryURL.appendingPathComponent("MoonbounceConfigs", isDirectory: true)
//        
//        do
//        {
//            try fileManager.createDirectory(at: moonbounceConfigDirectory, withIntermediateDirectories: true, attributes: nil)
//        }
//        catch (let error)
//        {
//            print("\nEncountered an error attempting to create our application support directory: \(error)\n")
//            XCTFail()
//            return
//        }
//        
//        let testConfigDirectoryURL = applicationDirectoryURL.appendingPathComponent("Default", isDirectory: true)
//        
//        do
//        {
//            try fileManager.createDirectory(at: testConfigDirectoryURL, withIntermediateDirectories: true, attributes: nil)
//        }
//        catch (let error)
//        {
//            print("\nEncountered an error attempting to create our application support directory: \(error)\n")
//            XCTFail()
//            return
//        }
//        
//        // Replicant Config
//        guard createReplicantConfig(inDirectory: testConfigDirectoryURL)
//        else
//        {
//            XCTFail()
//            return
//        }
//        
//        // Replicant Client Config
//        guard createReplicantClientConfig(inDirectory: testConfigDirectoryURL)
//        else
//        {
//            XCTFail()
//            return
//        }
//        
//        let zipPath = moonbounceConfigDirectory.appendingPathComponent("default.moonbounce")
//        
//        // Check if an old config already exists and delete it so we can save the new one.
//        if fileManager.fileExists(atPath: zipPath.path)
//        {
//            do
//            {
//                try fileManager.removeItem(at: zipPath)
//            }
//            catch (let error)
//            {
//                print("\nAttempted to delete an old file at path \(zipPath) and failed. \nError: \(error)\n")
//            }
//        }
//        
//        // Zip the files and save to the temp directory.
//        do
//        {
//            try fileManager.zipItem(at: testConfigDirectoryURL, to: zipPath)
//            print("\nZipped Item to :\(zipPath)\n")
//        }
//        catch (let error)
//        {
//            print("\nUnable to zip config directory for export!\nError: \(error)\n")
//            XCTFail()
//        }
//    }
//    
//    func createReplicantConfig(inDirectory destDirectory: URL) -> Bool
//    {
//        guard let addSequence = SequenceModel(sequence: "Hello, hello!".data, length: 120)
//            else
//        {
//            print("\nUnable to generate an add sequence.\n")
//            return false
//        }
//        
//        guard let removeSequence = SequenceModel(sequence: "Goodbye!".data, length: 200)
//            else
//        {
//            print("\nUnable to generate a remove sequence.\n")
//            return false
//        }
//        
//        guard let replicantConfig = ReplicantConfig(serverPublicKey: "ReplaceMe".data, chunkSize: 800, chunkTimeout: 120, toneBurst: nil)
//            else
//        {
//            print("\nUnable to generate a replicant config struct.\n")
//            return false
//        }
//        
//        // Convert config to JSON
//        guard let jsonData = replicantConfig.createJSON()
//            else
//        {
//            print("\nUnable to create JSON from replicant config.\n")
//            return false
//        }
//        
//        // Save JSON to the destination directory
//        let fileManager = FileManager.default
//        let fileName = "replicant.config"
//        let path = destDirectory.appendingPathComponent(fileName).path
//        let configCreated = fileManager.createFile(atPath: path, contents: jsonData, attributes: nil)
//        
//        if configCreated
//        {
//            return true
//        }
//        else
//        {
//            print("\nUnable to create file at path: \(path)\n")
//            return false
//        }
//    }
//    
//    func createReplicantClientConfig(inDirectory destDirectory: URL) -> Bool
//    {
//        guard let port = NWEndpoint.Port(rawValue: 3006)
//        else
//        {
//            return false
//        }
//        
//        let host = NWEndpoint.Host("165.337.74.150")
//        let clientConfig = ClientConfig(withPort: port, andHost: host)
//        
//        guard let jsonData = clientConfig.createJSON()
//        else
//        {
//            print("\nUnable to create JSON from client config.\n")
//            return false
//        }
//        
//        // Save JSON to the destination directory
//        let fileManager = FileManager.default
//        let fileName = "replicantclient.config"
//        let path = destDirectory.appendingPathComponent(fileName).path
//        let configCreated = fileManager.createFile(atPath: path, contents: jsonData, attributes: nil)
//        
//        if configCreated
//        {
//            return true
//        }
//        else
//        {
//            print("\nUnable to create file at path: \(path)\n")
//            return false
//        }
//    }
//    
//    func getApplicationDirectory() -> URL?
//    {
//        let fileManager = FileManager.default
//        var directoryPath: URL
//        
//        // Find the application support directory in the home directory.
//        let appSupportDir = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
//        
//        guard appSupportDir.count > 0
//            else
//        {
//            //FIXME: This is the approach taken in the apple docs but...
//            print("Something went wrong, the app support directory is empty.")
//            return nil
//        }
//        
//        print("\nAppSupport Directory: \(appSupportDir)\n")
//        directoryPath = appSupportDir[0]
//        
//        // If the directory does not exist, this method creates it.
//        // This method is only available in macOS 10.7 and iOS 5.0 or later.
//        
//        do
//        {
//            try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
//        }
//        catch (let error)
//        {
//            print("\nEncountered an error attempting to create our application support directory: \(error)\n")
//            return nil
//        }
//        
//        return directoryPath
//    }

}
