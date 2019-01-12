//
//  MoonbounceTests.swift
//  MoonbounceTests
//
//  Created by Adelita Schule on 1/10/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import XCTest
import ReplicantSwift
import Replicant
import Datable
import INI
import ZIPFoundation

class MoonbounceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateConfigs()
    {
        guard let testConfigDirectoryURL = getApplicationDirectory()
        else
        {
            XCTFail()
            return
        }
        
        // Replicant Config
        guard createReplicantConfig(inDirectory: testConfigDirectoryURL)
        else
        {
            XCTFail()
            return
        }
        
        // WireGuard Config
        guard createWireGuardConfig(inDirectory: testConfigDirectoryURL)
        else
        {
            XCTFail()
            return
        }
        
        let zipPath = testConfigDirectoryURL.appendingPathComponent("defaultTestConfig.moonbounce")
        let fileManager = FileManager()
        
        // Check if an old config already exists and delete it so we can save the new one.
        if fileManager.fileExists(atPath: zipPath.path)
        {
            do
            {
                try fileManager.removeItem(at: zipPath)
            }
            catch (let error)
            {
                print("\nAttempted to delete an old file at path \(zipPath) and failed. \nError: \(error)\n")
            }
        }
        
        // Zip the files and save to the temp directory.
        do
        {
            try fileManager.zipItem(at: testConfigDirectoryURL, to: zipPath)
            print("\nZipped Item to :\(zipPath)\n")
        }
        catch (let error)
        {
            print("\nUnable to zip config directory for export!\nError: \(error)\n")
            XCTFail()
        }
    }
    
    func createReplicantConfig(inDirectory destDirectory: URL) -> Bool
    {
        guard let addSequence = SequenceModel(sequence: "Hello, hello!".data, length: 120)
            else
        {
            print("\nUnable to generate an add sequence.\n")
            return false
        }
        
        guard let removeSequence = SequenceModel(sequence: "Goodbye!".data, length: 200)
            else
        {
            print("\nUnable to generate a remove sequence.\n")
            return false
        }
        
        guard let replicantConfig = ReplicantConfig(serverPublicKey: "ReplaceMe".data, chunkSize: 800, chunkTimeout: 120, addSequences: [addSequence], removeSequences: [removeSequence])
            else
        {
            print("\nUnable to generate a replicant config struct.\n")
            return false
        }
        
        // Convert config to JSON
        guard let jsonData = replicantConfig.createJSON()
            else
        {
            print("\nUnable to create JSON from replicant config.\n")
            return false
        }
        
        // Save JSON to the destination directory
        let fileManager = FileManager.default
        let fileName = "replicant.config"
        let path = destDirectory.appendingPathComponent(fileName).path
        let configCreated = fileManager.createFile(atPath: path, contents: jsonData, attributes: nil)
        
        if configCreated
        {
            return true
        }
        else
        {
            print("\nUnable to create file at path: \(path)\n")
            return false
        }
    }
    
    func createWireGuardConfig(inDirectory destDirectory: URL) -> Bool
    {
        guard let wgConfigURL = Bundle.main.url(forResource: "utun9", withExtension: "conf")
            else
        {
            print("\nUnable to find the wireguard config file.\n")
            XCTFail()
            return false
        }
        
        do
        {
            let wgConfigINI = try parseINI(filename: wgConfigURL.path)
            
            guard let privKeyString = wgConfigINI["Interface"]?["PrivateKey"]
                else
            {
                print("\nUnable to get private key from config file.\n")
                XCTFail()
                return false
            }
            
            guard let pubKeyString = wgConfigINI["Peer"]?["PublicKey"]
                else
            {
                print("\nUnable to get public key from config file.\n")
                XCTFail()
                return false
            }
            
            guard let endpointString = wgConfigINI["Peer"]?["Endpoint"]
                else
            {
                print("\nUnable to get endpoint from config file.\n")
                XCTFail()
                return false
            }
            
            let endpointArray = endpointString.components(separatedBy: ":")
            XCTAssert(endpointArray.count >= 2)
            
            // Copy File to Test Destination Directory
            let fileManager = FileManager.default
            let filename = "wireguard.config"
            let testWGConfigURL = destDirectory.appendingPathComponent(filename)
            
            if fileManager.fileExists(atPath: testWGConfigURL.path)
            {
                do
                {
                    try fileManager.removeItem(at: testWGConfigURL)
                }
                catch
                {
                    print("\nFile already exists at path \(testWGConfigURL), but we were unable to delete the old file.\n")
                    return false
                }
            }
            
            do
            {
                try fileManager.copyItem(at: wgConfigURL, to: testWGConfigURL)
            }
            catch (let error)
            {
                print("\nUnable to copy WireGuard Config: \(error)\n")
                return false
            }
        }
        catch (let error)
        {
            print("\nUnable to parse wireguard config. Is it a valid INI? Error: \(error)\n")
            XCTFail()
            return false
        }
        
        return true
    }
    
    func getApplicationDirectory() -> URL?
    {
        let directoryName = "org.OperatorFoundation.Moonbounce.MacOS"
        
        let fileManager = FileManager.default
        var directoryPath: URL
        
        // Find the application support directory in the home directory.
        let appSupportDir = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        
        guard appSupportDir.count > 0
            else
        {
            //FIXME: This is the approach taken in the apple docs but...
            print("Something went wrong, the app support directory is empty.")
            return nil
        }
        
        print("\nAppSupport Directory: \(appSupportDir)\n")
        
        // Append the bundle ID to the URL for the
        // Application Support directory
        directoryPath = appSupportDir[0].appendingPathComponent("\(directoryName)/testConfig")
        
        // If the directory does not exist, this method creates it.
        // This method is only available in macOS 10.7 and iOS 5.0 or later.
        
        do
        {
            try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch (let error)
        {
            print("\nEncountered an error attempting to create our application support directory: \(error)\n")
            return nil
        }
        
        return directoryPath
    }

}
