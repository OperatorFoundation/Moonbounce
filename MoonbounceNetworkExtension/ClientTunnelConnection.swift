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
import Replicant
import Flower
import InternetProtocols

/// An object used to tunnel IP packets using the SimpleTunnel protocol.
public class ClientTunnelConnection
{
    /// The flow of IP packets.
    let packetFlow: NEPacketTunnelFlow
    let log: Logger
    let replicantConnection: ReplicantConnection
    var ipAllocationMessage: Message? = nil

    // MARK: Initializers
    public init(clientPacketFlow: NEPacketTunnelFlow, replicantConnection: ReplicantConnection, logger: Logger)
    {
        self.log = logger
        self.packetFlow = clientPacketFlow
        self.replicantConnection = replicantConnection
        logger.debug("Initialized ClientTunnelConnection")
    }

    // MARK: Interface
    
    /// Wait for IP assignment from the server
    public func waitForIPAssignment()
    {
        replicantConnection.readMessages(log: self.log)
        {
            (message) in

            self.log.debug("🌷 replicantConnection.readMessages callback message: \(message.description) 🌷")
            switch message
            {
                case .IPAssignV4(_),
                     .IPAssignV6(_):
                     //.IPAssignDualStack(_, _):
                    guard self.ipAllocationMessage == nil else {break}
                    self.ipAllocationMessage = message
                case .IPDataV4(let data):
                    self.log.debug("IPDataV4 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [4])
                case .IPDataV6(let data):
                    self.log.debug("IPDataV6 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [6])
                default:
                    self.log.error("unsupported message type")
            }
        }

    }
    
    /// Make the initial readPacketsWithCompletionHandler call.
    public func startHandlingPackets()
    {
        log.debug("Start handling packets called.")
        DispatchQueue.global(qos: .userInitiated).async
        {
            self.log.debug("calling packetsToMessages async")
            self.packetsToMessages()
        }
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            self.log.debug("calling messagesToPackets async")
            self.messagesToPackets()
        }
    }
    
    /// Handle packets coming from the packet flow.
    func packetsToMessages()
    {
        log.debug("Handle Packets Called")
        // This is where you should send the packets to the server.

        // Read more packets.
        self.packetFlow.readPackets
        {
            (inPackets, inProtocols) in

            self.log.debug("Reached the readPackets callback :)")
            
            let packages = zip(inPackets, inProtocols)

            for (packet, prot) in packages
            {
                // Check if protocol is v4 or v6
                switch prot
                {
                    case NSNumber(value: AF_INET):
                        self.log.debug("Ipv4 protocol")

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

                            if let error = maybeError
                            {
                                self.log.error("Error writing message: \(error)")
                            }
                        })
                    default:
                        self.log.error("Unsupported protocol type: \(prot)")
                }
            }

            self.packetsToMessages()
        }
    }
        
    func messagesToPackets()
    {
        self.log.debug("calling messagesToPackets!")
        replicantConnection.readMessages(log: self.log)
        {
            (message) in

            self.log.debug("🌷 replicantConnection.readMessages callback message: \(message.description) 🌷")
            switch message
            {
                case .IPAssignV4(_),
                     .IPAssignV6(_):
                     //.IPAssignDualStack(_, _):
                    guard self.ipAllocationMessage == nil else {break}
                    self.ipAllocationMessage = message
                case .IPDataV4(let data):
                    self.log.debug("IPDataV4 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [4])
                case .IPDataV6(let data):
                    self.log.debug("IPDataV6 calling write packets.")
                    self.packetFlow.writePackets([data], withProtocols: [6])
                default:
                    self.log.error("unsupported message type")
            }
        }
    }
    
    /// Send packets to the virtual interface to be injected into the IP stack.
    public func sendPackets(_ packets: [Data], protocols: [NSNumber])
    {
        packetFlow.writePackets(packets, withProtocols: protocols)
    }
}
