//
//  MoonbounceTests.swift
//  MoonbounceTests
//
//  Created by Adelita Schule on 1/10/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Datable
import Logging
@testable import Moonbounce
import Network
import NetworkExtension
import SwiftHexTools
import TransmissionAsync
import XCTest

class MoonbounceTests: XCTestCase {
    func testTCPConnect() async throws {
        let logger = Logger(label: "MoonbounceTest")
        let connection = try await AsyncTcpSocketConnection("", 7, logger)
    }
    
    func testTCP() async throws {
        let testData = Data(repeating: "a".data[0], count: 10)
        let logger = Logger(label: "MoonbounceTest")
        let connection = try await AsyncTcpSocketConnection("", 7, logger)
        try await connection.write(testData)
        let receivedData = try await connection.readSize(testData.count)
        XCTAssertEqual(testData, receivedData)
    }
    
    func testTCPBigData() async throws {
        let testData = Data(repeating: "a".data[0], count: 2000)
        let logger = Logger(label: "MoonbounceTest")
        let connection = try await AsyncTcpSocketConnection("", 7, logger)
        try await connection.write(testData)
        let receivedData = try await connection.readSize(testData.count)
        XCTAssertEqual(testData, receivedData)
    }
    
    func testUDP() {
        let testData = Data(repeating: "a".data[0], count: 10)
        let host: Network.NWEndpoint.Host = ""
        let port: Network.NWEndpoint.Port = 7
        let connection = NWConnection(host: host, port: port, using: .udp)
        connection.stateUpdateHandler = {
            state in
            
            switch state {
                case .ready:
                    connection.send(content: testData, completion: NWConnection.SendCompletion.contentProcessed({
                        error in
                        
                        guard error == nil else {
                            XCTFail()
                            return
                        }
                        
                        connection.receiveMessage(completion: {
                            data, context, isComplete, error in
                            
                            guard error == nil else {
                                XCTFail()
                                return
                            }
                            
                            XCTAssertEqual(testData, data)
                        })
                    }))
            default:
                print(state)
            }
        }
    }
}
