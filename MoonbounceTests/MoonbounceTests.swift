//
//  MoonbounceTests.swift
//  MoonbounceTests
//
//  Created by Adelita Schule on 1/10/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import XCTest
import Logging
import Network
import NetworkExtension
import SwiftHexTools
import ReplicantSwift
import Replicant
import Datable
import Flower
import ZIPFoundation
@testable import Moonbounce

class MoonbounceTests: XCTestCase {
    
//    override class func setUp() {
//        LoggingSystem.bootstrap(StreamLogHandler.standardError)
//        }
    
//    func testConnectToServer()
//    {
//        guard let controller = ConfigController(), let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Unable to connect, unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig, isEnabled: true)
//        {
//            (maybeLoadError) in
//
//            if let loadError = maybeLoadError
//            {
//                print("Unable to connect, error loading from preferences: \(loadError)")
//                XCTFail()
//                return
//            }
//
//            guard let vpnPreference = VPNPreferencesController.shared.maybeVPNPreference
//            else
//            {
//                print("Unable to connect, vpnPreference is nil.")
//                XCTFail()
//                return
//            }
//
//            if vpnPreference.connection.status == .disconnected || vpnPreference.connection.status == .invalid
//            {
//                print("\nConnect pressed, starting logging loop.\n")
//                LoggingController.shared.startLoggingLoop()
//
//                do
//                {
//                    print("\nCalling startVPNTunnel on vpnPreference.connection.\n")
//                    try vpnPreference.connection.startVPNTunnel()
//
//                    // Fetch URL here
//
//                }
//                catch
//                {
//                    NSLog("\nFailed to start the VPN: \(error.localizedDescription)\n")
//                    LoggingController.shared.stopLoggingLoop()
//                }
//
//            }
//            else
//            {
//                LoggingController.shared.stopLoggingLoop()
//                vpnPreference.connection.stopVPNTunnel()
//            }
//        }
//    }
    
    // TODO: Polish
//    func testReplicantClientConnectionWithPolish()
//    {
//       let writeExpectation = expectation(description: "wrote")
//
//        let polishConfig = SilverClientConfig(
//        guard let replicantConfig = ReplicantConfig(polish: nil, toneBurst: nil)
//        else
//        {
//            XCTFail()
//            return
//        }
//
//        let connectionFactory = ReplicantConnectionFactory(host: "127.0.0.1", port: 1234, config: replicantConfig)
//
//        guard var connection = connectionFactory.connect(using: .tcp)
//        else
//        {
//            XCTFail()
//            return
//        }
//
//        connection.stateUpdateHandler =
//        {
//            (newState) in
//
//            switch newState
//            {
//            case .ready:
//                let message = Message.IPDataV4("Hello".data)
//                connection.writeMessage(message: message)
//                {
//                    (maybeWriteError) in
//
//                    if let writeError = maybeWriteError
//                    {
//                        print("***Write error: \(writeError)")
//                        XCTFail()
//                        return
//                    }
//                    else
//                    {
//                        writeExpectation.fulfill()
//                    }
//                }
//            default:
//                print("***Not ready: \(newState)")
//            }
//        }
//
//        connection.start(queue: DispatchQueue(label: "TestQueue") )
//        wait(for: [writeExpectation], timeout: 1)
//    }
    
    func testPing() {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")
        
         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

         let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .tcp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
                
                case .ready:
                    connection.readMessage { ipAssignMessage in
                        switch ipAssignMessage {
                            case .IPAssignV4(let sourceAddress):
                                print(sourceAddress)
                                print(sourceAddress.rawValue.hex)
                                print(sourceAddress.rawValue.array)
                                let newPacket = "45000054edfa00004001baf1\(sourceAddress.rawValue.hex)080808080800335dde64021860f5bcab0009db7808090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637"
                                print(newPacket)
                                let message = Message.IPDataV4(Data(hex: newPacket)!)
                                connection.writeMessage(message: message)
                                {
                                    (maybeWriteError) in

                                    if let writeError = maybeWriteError
                                    {
                                        print("***Write error: \(writeError)")
                                        XCTFail()
                                        return
                                    }
                                    else
                                    {
                                        writeExpectation.fulfill()
                                        connection.readMessage { message in
                                            readExpectation.fulfill()
                                        }
                                    }
                                }
                            default:
                                print("***Not ready: \(newState)")
                            }
                        }
                default:
                    XCTFail()
                    return
                    }
                }
        connection.start(queue: DispatchQueue(label: "TestQueue") )
        wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
    
    func testTCP() {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")
        
         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

         let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .tcp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
                
                case .ready:
                    connection.readMessage { ipAssignMessage in
                        switch ipAssignMessage {
                            case .IPAssignV4(let sourceAddress):
                                print(sourceAddress)
                                print(sourceAddress.rawValue.hex)
                                print(sourceAddress.rawValue.array)
                                //FIXME: this destaddr is the DO server, replace with google (172.18.128.1) and port 443
                                let destinationAddress = "a747b88e"
                                let destinationPort = "0016"
                                let newPacket = "450000400000400040060afc\(sourceAddress.rawValue.hex)\(destinationAddress)d716\(destinationPort)0ee2261300000000b002ffff2a3c0000020405b4010303060101080a2173adc90000000004020000"
                                print(newPacket)
                                let message = Message.IPDataV4(Data(hex: newPacket)!)
                                connection.writeMessage(message: message)
                                {
                                    (maybeWriteError) in

                                    if let writeError = maybeWriteError
                                    {
                                        print("***Write error: \(writeError)")
                                        XCTFail()
                                        return
                                    }
                                    else
                                    {
                                        writeExpectation.fulfill()
                                        connection.readMessage { message in
                                            readExpectation.fulfill()
                                        }
                                    }
                                }
                            default:
                                print("***Not ready: \(newState)")
                            }
                        }
                default:
                    XCTFail()
                    return
                    }
                }
        connection.start(queue: DispatchQueue(label: "TestQueue") )
        wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
    
    func testUDP() {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")
        
         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

         let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .udp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
                
                case .ready:
                    connection.readMessage { ipAssignMessage in
                        switch ipAssignMessage {
                            case .IPAssignV4(let ipv4Address):
                                print(ipv4Address)
                                print(ipv4Address.rawValue.hex)
                                print(ipv4Address.rawValue.array)
                                let newPacket = "4500003dbfca00004011f783\(ipv4Address.rawValue.hex)8efa72bdd8a801bb00293d7550fa2df0bc8cdbcdf2a9af346c7bdb1f6972e32fc7f45c9a774e6e698999fb1e48"
                                print(newPacket)
                                let message = Message.IPDataV4(Data(hex: newPacket)!)
                                connection.writeMessage(message: message)
                                {
                                    (maybeWriteError) in

                                    if let writeError = maybeWriteError
                                    {
                                        print("***Write error: \(writeError)")
                                        XCTFail()
                                        return
                                    }
                                    else
                                    {
                                        writeExpectation.fulfill()
                                        connection.readMessage { message in
                                            readExpectation.fulfill()
                                        }
                                    }
                                }
                            default:
                                print("***Not ready: \(newState)")
                            }
                        }
                default:
                    XCTFail()
                    return
                    }
                }
        connection.start(queue: DispatchQueue(label: "TestQueue") )
        wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
    
    func testUDPWithVPN() {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")
        
         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }

         guard var connection = NWConnection(host: "206.189.173.164", port: 4567, using: <#T##NWParameters#>)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
                
                case .ready:
                    connection.readMessage { ipAssignMessage in
                        switch ipAssignMessage {
                            case .IPAssignV4(let ipv4Address):
                                print(ipv4Address)
                                print(ipv4Address.rawValue.hex)
                                print(ipv4Address.rawValue.array)
                                let newPacket = "4500003dbfca00004011f783\(ipv4Address.rawValue.hex)8efa72bdd8a801bb00293d7550fa2df0bc8cdbcdf2a9af346c7bdb1f6972e32fc7f45c9a774e6e698999fb1e48"
                                print(newPacket)
                                let message = Message.IPDataV4(Data(hex: newPacket)!)
                                connection.writeMessage(message: message)
                                {
                                    (maybeWriteError) in

                                    if let writeError = maybeWriteError
                                    {
                                        print("***Write error: \(writeError)")
                                        XCTFail()
                                        return
                                    }
                                    else
                                    {
                                        writeExpectation.fulfill()
                                        connection.readMessage { message in
                                            readExpectation.fulfill()
                                        }
                                    }
                                }
                            default:
                                print("***Not ready: \(newState)")
                            }
                        }
                default:
                    XCTFail()
                    return
                    }
                }
        connection.start(queue: DispatchQueue(label: "TestQueue") )
        wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
    
    func testReplicantClientConnectionToServer()
    {
       let writeExpectation = expectation(description: "wrote")

        guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
        else
        {
            XCTFail()
            return
        }
        let logger = Logger(label: "MoonbounceTest")

        let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

        guard var connection = connectionFactory.connect(using: .tcp)
        else
        {
            XCTFail()
            return
        }

        connection.stateUpdateHandler =
        {
            (newState) in

            switch newState
            {
            case .ready:
                let message = Message.IPDataV4("Hello".data)
                connection.writeMessage(message: message)
                {
                    (maybeWriteError) in

                    if let writeError = maybeWriteError
                    {
                        print("***Write error: \(writeError)")
                        XCTFail()
                        return
                    }
                    else
                    {
                        writeExpectation.fulfill()
                    }
                }
            default:
                print("***Not ready: \(newState)")
            }
        }

        connection.start(queue: DispatchQueue(label: "TestQueue") )
        wait(for: [writeExpectation], timeout: 1)
    }

    func testSendAndReceiveData()
    {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")

         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

         let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .tcp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
             case .ready:
                 let message = Message.IPDataV4("Hello".data)
                 connection.writeMessage(message: message)
                 {
                     (maybeWriteError) in

                     if let writeError = maybeWriteError
                     {
                         print("***Write error: \(writeError)")
                         XCTFail()
                         return
                     }
                     else
                     {
                         writeExpectation.fulfill()
                        connection.readMessage { message in
                            readExpectation.fulfill()
                        }
                     }
                 }
             default:
                 print("***Not ready: \(newState)")
             }
         }

         connection.start(queue: DispatchQueue(label: "TestQueue") )
         wait(for: [writeExpectation, readExpectation], timeout: 1000)
        
        
    }
    
    func testSendAndReceiveByte()
    {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")

         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

         let connectionFactory = ReplicantConnectionFactory(host: "138.197.196.245", port: 1234, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .tcp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
             case .ready:
                let message = "hi".data
                connection.send(content: message, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed(
                                    { maybeWriteError in
                    if let writeError = maybeWriteError
                    {
                        print("***Write error: \(writeError)")
                        XCTFail()
                        return
                    }
                    else
                    {
                        writeExpectation.fulfill()
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { maybeData, maybeContext, isComplete, maybeError in
                            readExpectation.fulfill()
                        }
                    }
                }))
             default:
                 print("***Not ready: \(newState)")
             }
            
         }
         connection.start(queue: DispatchQueue(label: "TestQueue") )
         wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
    
    func testDefaultMoonbounceConfig() {
        // its getting the config from /Users/bluesaxorcist/Library/Developer/Xcode/DerivedData/Moonbounce-bwswfokwswbfrughpywkefjxmjtx/Build/Products/Debug/Moonbounce.app/Contents/Resources/Default
        let config = ConfigController().getDefaultMoonbounceConfig()
        guard (config != nil) else {
            XCTFail()
            return
        }
        let host = config!.clientConfig.host
        let port = config!.clientConfig.port
        XCTAssertNotNil(config)
        XCTAssertEqual(host, "138.197.196.245")
        XCTAssertEqual(port,  1234)
    }
    
    func testSendAndReceiveByteWithConfig()
    {
        let writeExpectation = expectation(description: "wrote")
        let readExpectation = expectation(description: "read")

        guard let config = ConfigController().getDefaultMoonbounceConfig() else {
            XCTFail()
            return
        }
        
        // TODO: Figure out how to use the replicantConfig from the default config
         guard let replicantConfig = ReplicantConfig<SilverClientConfig>(polish: nil, toneBurst: nil)
         else
         {
             XCTFail()
             return
         }
         let logger = Logger(label: "MoonbounceTest")

        let connectionFactory = ReplicantConnectionFactory(host: config.clientConfig.host, port: config.clientConfig.port, config: replicantConfig, log: logger)

         guard var connection = connectionFactory.connect(using: .tcp)
         else
         {
             XCTFail()
             return
         }

         connection.stateUpdateHandler =
         {
             (newState) in

             switch newState
             {
             case .ready:
                let message = "hi".data
                connection.send(content: message, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed(
                                    { maybeWriteError in
                    if let writeError = maybeWriteError
                    {
                        print("***Write error: \(writeError)")
                        XCTFail()
                        return
                    }
                    else
                    {
                        writeExpectation.fulfill()
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { maybeData, maybeContext, isComplete, maybeError in
                            readExpectation.fulfill()
                        }
                    }
                }))
             default:
                 print("***Not ready: \(newState)")
             }
            
         }
         connection.start(queue: DispatchQueue(label: "TestQueue") )
         wait(for: [writeExpectation, readExpectation], timeout: 1000)
    }
//    func testVPNPreferencesUpdate()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//        let configController = ConfigController()
//
//        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Update test failed: unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig)
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                print("Error testing update: \(error.localizedDescription)")
//                XCTFail()
//            }
//
//            completionExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//
//    func testVPNPreferencesSetup()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//        let configController = ConfigController()
//
//        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Update test failed: unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        VPNPreferencesController.shared.setup(moonbounceConfig: moonbounceConfig)
//        {
//            (managerOrError) in
//
//            switch managerOrError
//            {
//            case .error(let error):
//                print("Error testing VPNPreferences setup: \(error.localizedDescription)")
//                XCTAssertNil(error)
//            case .value(let manager):
//                print("Setup test created a manager: \(manager.debugDescription)")
//            }
//
//            completionExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//
//    func testVPNPreferencesDeactivateNilPreference()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//        VPNPreferencesController.shared.maybeVPNPreference = nil
//
//        VPNPreferencesController.shared.deactivate
//        {
//            (maybeError) in
//
//            guard let _ = maybeError
//                else
//            {
//                XCTFail()
//                return
//            }
//
//            completionExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 3, handler: nil)
//    }
//
//    func testVPNPreferencesDeactivate()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//        let configController = ConfigController()
//
//        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Update test failed: unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig)
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                print("Error testing update: \(error.localizedDescription)")
//                XCTFail()
//            }
//
//            VPNPreferencesController.shared.deactivate
//            {
//                (maybeError) in
//
//                if let error = maybeError
//                {
//                    print("Error testing activate: \(error.localizedDescription)")
//                    XCTFail()
//                }
//
//                completionExpectation.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//
//    func testVPNPreferencesNewProtocolConfig()
//    {
//        let configController = ConfigController()
//
//        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Update test failed: unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        guard let _ = VPNPreferencesController.shared.newProtocolConfiguration(moonbounceConfig: moonbounceConfig)
//        else
//        {
//            XCTFail()
//            return
//        }
//    }
//
//    func testVPNPreferencesLoad()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//
//        VPNPreferencesController.shared.load
//        {
//           (eitherVPNPreference) in
//
//            switch eitherVPNPreference
//            {
//                case .error(_):
//                    XCTFail()
//                    return
//                case .value( _):
//                    print("Load test returned a VPNPreference")
//            }
//
//            completionExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//
//    func testVPNPreferenceSaveNilPreference()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//
//        VPNPreferencesController.shared.maybeVPNPreference = nil
//
//        VPNPreferencesController.shared.save
//        {
//            (maybeError) in
//
//            guard let _ = maybeError
//                else
//            {
//                XCTFail()
//                return
//            }
//
//            completionExpectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//
//    func testVPNPreferenceSave()
//    {
//        let completionExpectation = expectation(description: "completion handler called")
//        let configController = ConfigController()
//
//        guard let controller = configController, let moonbounceConfig = controller.getDefaultMoonbounceConfig()
//        else
//        {
//            print("Update test failed: unable to load default config.")
//            XCTFail()
//            return
//        }
//
//        VPNPreferencesController.shared.updateConfiguration(moonbounceConfig: moonbounceConfig)
//        {
//            (maybeError) in
//
//            if let error = maybeError
//            {
//                print("Error testing update: \(error.localizedDescription)")
//                completionExpectation.fulfill()
//                XCTFail()
//            }
//
//            VPNPreferencesController.shared.save
//            {
//                (maybeError) in
//
//                if let error = maybeError
//                {
//                    print("Error testing VPNPreference save: \(error)")
//                    XCTFail()
//                }
//
//                completionExpectation.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }

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
