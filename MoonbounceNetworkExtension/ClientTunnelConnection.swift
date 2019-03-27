//
//  File.swift
//  MoonbounceiOSNetworkExtension
//
//  Created by Mafalda on 2/12/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import NetworkExtension
import Replicant
import SwiftQueue
import Flower

/// An object used to tunnel IP packets using the SimpleTunnel protocol.
public class ClientTunnelConnection
{
    /// The flow of IP packets.
    let packetFlow: NEPacketTunnelFlow
    
    /// A Queue of Log Messages
    var logQueue = Queue<String>()
    let replicantConnection: ReplicantConnection
    
    // MARK: Initializers
    
    init(clientPacketFlow: NEPacketTunnelFlow, replicantConnection: ReplicantConnection, logQueue: Queue<String>)
    {
        self.logQueue = logQueue
        self.packetFlow = clientPacketFlow
        self.replicantConnection = replicantConnection
        self.logQueue.enqueue("Initialized ClientTunnelConnection")
    }

    // MARK: Interface
    
    /// Handle packets coming from the packet flow.
    func handlePackets()
    {
        logQueue.enqueue("Handle Packets Called")
        // This is where you should send the packets to the server.

        // Read more packets.
        self.packetFlow.readPackets
        {
            inPackets, inProtocols in

            let packages = zip(inPackets, inProtocols)

            for (packet, prot) in packages
            {
                // Check if protocol is v4 or v6
                switch prot
                {
                case 4:
                    self.logQueue.enqueue("Ipv4 protocol")

                    let message = Message.IPDataV4(packet)
                    self.replicantConnection.writeMessage(message: message, completion:
                    {
                        (maybeError) in

                        if let error = maybeError
                        {
                            self.logQueue.enqueue("Error writing message: \(error)")
                        }
                    })
                case 6:
                    self.logQueue.enqueue("IPv6 prtocol")
                    let message = Message.IPDataV6(packet)
                    self.replicantConnection.writeMessage(message: message, completion:
                    {
                        (maybeError) in

                        if let error = maybeError
                        {
                            self.logQueue.enqueue("Error writing message: \(error)")
                        }
                    })
                default:
                    self.logQueue.enqueue("Unsupported protocol type: \(prot)")
                }
            }

            self.handlePackets()
        }
    }
    
    /// Make the initial readPacketsWithCompletionHandler call.
    func startHandlingPackets()
    {
        // FIXME: async block
        DispatchQueue.global(qos: .userInitiated).async
        {
            self.handlePackets()
        }
    }
    
    /// Send packets to the virtual interface to be injected into the IP stack.
    public func sendPackets(_ packets: [Data], protocols: [NSNumber])
    {
        packetFlow.writePackets(packets, withProtocols: protocols)
    }
    
    public func startGettingPackets()
    {
        replicantConnection.readMessages
        {
            message in

            switch message
            {
            case .IPDataV4(let data):
                self.logQueue.enqueue("IPDataV4 calling write packets.")
                self.packetFlow.writePackets([data], withProtocols: [4])
            case .IPDataV6(let data):
                self.logQueue.enqueue("IPDataV4 calling write packets.")
                self.packetFlow.writePackets([data], withProtocols: [6])
            default:
                self.logQueue.enqueue("unsupported message type")
            }
        }
    }
}
