//
//  File.swift
//  MoonbounceiOSNetworkExtension
//
//  Created by Mafalda on 2/12/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import Logging
import NetworkExtension
import ReplicantSwiftClient
import Flower
import InternetProtocols

/// An object used to tunnel IP packets using the SimpleTunnel protocol.
public class ClientTunnelConnection
{
    /// The flow of IP packets.
    let packetFlow: NEPacketTunnelFlow
    let log: Logger
    let flowerConnection: FlowerConnection
    var ipAllocationMessage: Message? = nil
    let messagesToPacketsQueue = DispatchQueue(label: "clientTunnelConnection: messagesToPackets")
    let packetsToMessagesQueue = DispatchQueue(label: "clientTunnelConnection: packetsToMessages")
    
    // MARK: Initializers
    public init(clientPacketFlow: NEPacketTunnelFlow, flowerConnection: FlowerConnection, logger: Logger)
    {
        self.log = logger
        self.packetFlow = clientPacketFlow
        self.flowerConnection = flowerConnection
        logger.debug("Initialized ClientTunnelConnection")
    }

<<<<<<< HEAD
=======
//    // MARK: Interface
//
//    /// Wait for IP assignment from the server
//    public func waitForIPAssignment()
//    {
//        replicantConnection.readMessages(log: self.log)
//        {
//            (message) in
//
//            self.log.debug("🌷 replicantConnection.readMessages callback message: \(message.description) 🌷")
//            switch message
//            {
//                case .IPAssignV4(_),
//                     .IPAssignV6(_):
//                     //.IPAssignDualStack(_, _):
//                    guard self.ipAllocationMessage == nil else {break}
//                    self.ipAllocationMessage = message
//                case .IPDataV4(let data):
//                    self.log.debug("IPDataV4 calling write packets.")
//                    self.packetFlow.writePackets([data], withProtocols: [4])
//                case .IPDataV6(let data):
//                    self.log.debug("IPDataV6 calling write packets.")
//                    self.packetFlow.writePackets([data], withProtocols: [6])
//                default:
//                    self.log.error("unsupported message type")
//            }
//        }
//
//    }
    
>>>>>>> b1fd7f9f7ac7f2f324bd511d77c1ad9c97cb2ff8
    /// Make the initial readPacketsWithCompletionHandler call.
    public func startHandlingPackets()
    {
        self.log.debug("7. Start handling packets called.")
        
        packetsToMessagesQueue.async
        {
            self.log.debug("calling packetsToMessages async")
            self.packetsToMessages()
        }
        
        messagesToPacketsQueue.async
        {
            self.log.debug("calling messagesToPackets async")
            self.messagesToPackets()
        }
    }
    
    /// Handle packets coming from the packet flow.
    func packetsToMessages()
    {
        log.debug("8. Handle Packets Called")
        // This is where you should send the packets to the server.

        // Read more packets.
        let lock = DispatchGroup()

        while true
        {
            lock.enter()
            self.packetFlow.readPackets
            {
                (inPackets, inProtocols) in

<<<<<<< HEAD
                self.log.debug("Reached the readPackets callback :)")

                let packages = zip(inPackets, inProtocols)

                for (packet, prot) in packages
                {
                    // Check if protocol is v4 or v6
                    switch prot
                    {
                        case NSNumber(value: AF_INET):
                            self.log.debug("Ipv4 protocol")

                            // Encapsulates packages into Messages (using Flower)
                            self.log.debug("packet: \(packet)")
                            let message = Message.IPDataV4(packet)
                            self.log.debug("🌷 encapsulated into Flower Message: \(message.description) 🌷")
=======
                        if let ipv4Packet = IPv4(data: packet) {
                            if ipv4Packet.destinationAddress == Data(array: [8, 8, 8, 8]) {
                                self.log.debug("saw a packet for 8.8.8.8!")
                            }
                        }
                        // Encapsulates packages into Messages (using Flower)
                        self.log.debug("packet: \(packet)")
                        let message = Message.IPDataV4(packet)
                        self.log.debug("🌷 encapsulated into Flower Message: \(message.description) 🌷")

                        self.replicantConnection.writeMessage(log: self.log, message: message, completion:
                        {
                            (maybeError) in

                            if let error = maybeError
                            {
                                self.log.error("Error writing message: \(error)")
                            }
                        })
                    case NSNumber(value: AF_INET6):
                        self.log.debug("IPv6 protocol")
                        let message = Message.IPDataV6(packet)
                        self.replicantConnection.writeMessage(log: self.log, message: message, completion:
                        {
                            (maybeError) in
>>>>>>> b1fd7f9f7ac7f2f324bd511d77c1ad9c97cb2ff8

                            self.flowerConnection.writeMessage(message: message)
                        case NSNumber(value: AF_INET6):
                            self.log.debug("IPv6 protocol")
                            let message = Message.IPDataV6(packet)
                            self.flowerConnection.writeMessage(message: message)
                        default:
                            self.log.error("Unsupported protocol type: \(prot)")
                    }
                }

                lock.leave()
            }

            lock.wait()
        }
    }
        
    func messagesToPackets()
    {
<<<<<<< HEAD
        while true
        {
            guard let message = flowerConnection.readMessage() else {return}

            self.log.debug("🌷 replicantConnection.readMessages callback message: \(message.description) 🌷")
            switch message
            {
                case .IPDataV4(let data):
                    self.log.debug("IPDataV4 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [4])
                case .IPDataV6(let data):
                    self.log.debug("IPDataV6 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [6])
                default:
                    self.log.error("unsupported message type")
=======
        self.log.debug("9. 📦 calling messagesToPackets! 📦")
        var counter = 0
        
        //replicantConnection.readMessages(log: self.log)
        while true
        {
            replicantConnection.readMessage(log: self.log)
            {
                message in
                
                counter += 1
                self.log.debug("🌷 📦readMessage called \(counter) times📦 🌷")
                self.log.debug("10. 🌷 📦replicantConnection.readMessages callback message: \(message.description)📦 🌷")
                switch message
                {
                    case .IPAssignV4(_),
                         .IPAssignV6(_):
                        self.log.debug("📦IPAssign message received.📦")
                         //.IPAssignDualStack(_, _):
                        guard self.ipAllocationMessage == nil else {break}
                        self.ipAllocationMessage = message
                    case .IPDataV4(let data):
                        self.log.debug("📦IPDataV4 calling write packets.📦")
                        self.packetFlow.writePackets([data], withProtocols: [4])
                    case .IPDataV6(let data):
                        self.log.debug("📦IPDataV6 calling write packets.📦")
                        self.packetFlow.writePackets([data], withProtocols: [6])
                    default:
                        self.log.error("📦unsupported message type📦")
                }
>>>>>>> b1fd7f9f7ac7f2f324bd511d77c1ad9c97cb2ff8
            }
        }
    }
}
