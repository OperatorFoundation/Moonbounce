//
//  PacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import NetworkExtension
import Network
import Replicant
import ReplicantSwift
import Flow
import SwiftQueue

class PacketTunnelProvider: NEPacketTunnelProvider
{
    private var networkMonitor: NWPathMonitor?
    
    private var ifname: String?
    //private var packetTunnelSettingsGenerator: PacketTunnelSettingsGenerator?
    
    var replicantConnectionFactory: ReplicantConnectionFactory?
    
    /// The tunnel connection.
    open var connection: ReplicantConnection?
    
    /// The completion handler to call when the tunnel is fully established.
    var pendingStartCompletion: ((Error?) -> Void)?
    
    /// The completion handler to call when the tunnel is fully disconnected.
    var pendingStopCompletion: (() -> Void)?
    
    /// To make sure that we don't try connecting repeatedly and unintentionally
    var connectionAttemptStatus: ConnectionAttemptStatus = .initialized
    
    /// The address of the tunnel server.
    open var remoteHost: String?
    
    /// A Queue of Log Messages
    var logQueue = Queue<String>()
    
    override init()
    {
        NSLog("\nQQQ provider init\n")
        logQueue.enqueue("\nQQQ provider init\n")
        super.init()
    }
    
    deinit
    {
        networkMonitor?.cancel()
    }
    
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
    {
        logQueue.enqueue("PacketTunnelProvider startTunnel called")
        
        switch connectionAttemptStatus
        {
        case .initialized:
            connectionAttemptStatus = .started
        case .started:
            logQueue.enqueue("start tunnel called when tunnel was already started.")
        case .connecting:
            connectionAttemptStatus = .started
        }
        
        // Save the completion handler for when the tunnel is fully established.
        pendingStartCompletion = completionHandler

        let activationAttemptId = options?["activationAttemptId"] as? String
        let errorNotifier = ErrorNotifier(activationAttemptId: activationAttemptId)
        
        guard let tunnelProviderProtocol = protocolConfiguration as? NETunnelProviderProtocol
        else
        {
            logQueue.enqueue("PacketTunnelProviderError: savedProtocolConfigurationIsInvalid")
            errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        guard let serverAddress: String = self.protocolConfiguration.serverAddress
            else
        {
            logQueue.enqueue("Unable to get the server address.")
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        self.remoteHost = serverAddress
        self.logQueue.enqueue("Server address: \(serverAddress)")
        
        guard let moonbounceConfig = Tunnel.getMoonbounceConfig(fromProtocolConfiguration: tunnelProviderProtocol)
            else
        {
            logQueue.enqueue("Unable to get moonbounce config from protocol.")
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        let tunnelConfiguration = Tunnel(moonbounceConfig: moonbounceConfig, completionHandler:
        {
            (maybeError) in
            
            if let error = maybeError
            {
                self.logQueue.enqueue(error.localizedDescription)
                completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)
                return
            }
            
        })

        guard let replicantConfig = moonbounceConfig.replicantConfig
            else
        {
            self.logQueue.enqueue("start tunnel failed to find a replicant configuration")
            completionHandler(TunnelError.badConfiguration)
            return
        }
        let host = moonbounceConfig.clientConfig.host
        let port = moonbounceConfig.clientConfig.port
        self.replicantConnectionFactory = ReplicantConnectionFactory(host: host,
                                                                     port: port,
                                                                     config: replicantConfig,
                                                                     logQueue: self.logQueue)
        
        self.logQueue.enqueue("\nReplicant Connection Factory Created.\nHost - \(host)\nPort - \(port)\n")
        
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor!.start(queue: DispatchQueue(label: "NetworkMonitor"))
        
        DispatchQueue.main.async
        {
            completionHandler(nil)
            self.readPackets()
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        networkMonitor?.cancel()
        networkMonitor = nil
        
        ErrorNotifier.removeLastErrorFile()

        logQueue.enqueue("closeTunnel Called")
        
        // Clear out any pending start completion handler.
        pendingStartCompletion?(TunnelError.internalError)
        pendingStartCompletion = nil
        
        // Close the tunnel connection.
        if let TCPConnection = connection
        {
            TCPConnection.cancel()
        }
        
        connectionAttemptStatus = .initialized
        pendingStopCompletion?()
        completionHandler()
    }
    
    func readPackets()
    {
        packetFlow.readPackets
        {
            (packetDatas, protocolNumbers) in
            
            let packets = zip(packetDatas, protocolNumbers)
            
            for (packetData, protocolNumber) in packets
            {
                // TODO: Do something with the data
            }
            
            self.readPackets()
        }
    }
    
    func writePackets(packetDatas: [Data], protocolNumbers: [NSNumber])
    {
        packetFlow.writePackets(packetDatas, withProtocols: protocolNumbers)
    }
    
    /// Handle IPC messages from the app.
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
//        switch connectionAttemptStatus
//        {
//        case .initialized:
//            logQueue.enqueue("handleAppMessage called before start tunnel. Doing nothing...")
//        case .started:
//            connectionAttemptStatus = .connecting
//            setTunnelSettings(configuration: [:])
//        case .connecting:
//            break
//        }
        
        var responseString = "Nothing to see here!"
        
        if let logMessage = self.logQueue.dequeue()
        {
            responseString = "\n*******\(logMessage)*******\n"
        }
        
        guard let responseData = responseString.data(using: String.Encoding.utf8)
        else
        {
            let someData = "Failed to encode message".data
            completionHandler?(someData)
            return
        }
        
        completionHandler?(responseData)
    }
    
    /// Create the tunnel network settings to be applied to the virtual interface.
    func createTunnelSettingsFromConfiguration(_ configuration: [NSObject: AnyObject]) -> NEPacketTunnelNetworkSettings?
    {
//        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "166.78.129.122")
//        let address = "192.168.2.1"
        let netmask = "255.255.255.0"
        
        //FIXME: tunnelAddress should be remoteHost,
        //configuration argument is ignored
        
        guard let tunnelAddress = remoteHost
        else
        {
            logQueue.enqueue("Unable to resolve tunnelAddress for NEPacketTunnelNetworkSettings")
            return nil
        }

        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
        newSettings.ipv4Settings = NEIPv4Settings(addresses: [tunnelAddress], subnetMasks: [netmask])
        newSettings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        newSettings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
        newSettings.tunnelOverheadBytes = 150
        
        return newSettings
    }
    
}

enum ConnectionAttemptStatus
{
    case initialized
    case started
    case connecting
}

public enum TunnelError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}
