//
//  PacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Logging
import NetworkExtension
import Network
import Replicant
import ReplicantSwift
import SwiftQueue
import LoggerQueue
import Flower

class PacketTunnelProvider: NEPacketTunnelProvider
{
    private var networkMonitor: NWPathMonitor?
    
    private var ifname: String?
    
    var replicantConnectionFactory: ReplicantConnectionFactory?
    
    /// The tunnel connection.
    open var connection: ReplicantConnection?
    
    /// The single logical flow of packets through the tunnel.
    var tunnelConnection: ClientTunnelConnection?
    
    /// The completion handler to call when the tunnel is fully established.
    var pendingStartCompletion: ((Error?) -> Void)?
    
    /// The completion handler to call when the tunnel is fully disconnected.
    var pendingStopCompletion: (() -> Void)?
    
    /// The last error that occurred on the tunnel.
    var lastError: Error?
    
    /// To make sure that we don't try connecting repeatedly and unintentionally
    var connectionAttemptStatus: ConnectionAttemptStatus = .initialized
    
    /// The address of the tunnel server.
    open var remoteHost: String?
    
    let loggerLabel = "org.OperatorFoundation.Moonbounce.MacOS.NetworkExtension"
    var logQueue: LoggerQueue
    var log: Logger!

    override init()
    {
        logQueue = LoggerQueue(label: loggerLabel)
        super.init()
        
        LoggingSystem.bootstrap
        {
            (label) in
            
            self.logQueue.queue.enqueue(LoggerQueueMessage(message: "Bootstrap closure."))
            return self.logQueue
        }
        
        log = Logger(label: loggerLabel)
        log.logLevel = .debug
        logQueue.queue.enqueue(LoggerQueueMessage(message: "Initialized PacketTunnelProvider"))
    }
    
    deinit
    {
        networkMonitor?.cancel()
    }

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
    {
        log.debug("👾 PacketTunnelProvider startTunnel called 👾")
        
        switch connectionAttemptStatus
        {
            case .initialized:
                // Start the tunnel
                connectionAttemptStatus = .started
            case .failed:
                // Start the tunnel
                connectionAttemptStatus = .started
            default:
                log.debug("start tunnel called when tunnel was already started.")
                return
        }
        
        // Save the completion handler for when the tunnel is fully established.
        pendingStartCompletion = completionHandler
        
        guard let tunnelProviderProtocol = protocolConfiguration as? NETunnelProviderProtocol
        else
        {
            log.debug("PacketTunnelProviderError: savedProtocolConfigurationIsInvalid")
            //errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        guard let serverAddress: String = self.protocolConfiguration.serverAddress
            else
        {
            log.error("Unable to get the server address.")
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        self.remoteHost = serverAddress
        self.log.debug("Server address: \(serverAddress)")
        
        guard let moonbounceConfig = ConfigController.getMoonbounceConfig(fromProtocolConfiguration: tunnelProviderProtocol)
            else
        {
            log.error("Unable to get moonbounce config from protocol.")
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }

        guard let replicantConfig = moonbounceConfig.replicantConfig
            else
        {
            self.log.debug("start tunnel failed to find a replicant configuration")
            completionHandler(TunnelError.badConfiguration)
            return
        }
        
        let host = moonbounceConfig.clientConfig.host
        let port = moonbounceConfig.clientConfig.port
        self.replicantConnectionFactory = ReplicantConnectionFactory(host: host,
                                                                     port: port,
                                                                     config: replicantConfig,
                                                                     log: log)
        
        self.log.debug("\nReplicant Connection Factory Created.\nHost - \(host)\nPort - \(port)\n")
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor!.start(queue: DispatchQueue(label: "NetworkMonitor"))
    
        pendingStartCompletion = completionHandler
        connectToServer()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        networkMonitor?.cancel()
        networkMonitor = nil
        
        ErrorNotifier.removeLastErrorFile()

        log.debug("closeTunnel Called")
        
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
    
    func writePackets(packetDatas: [Data], protocolNumbers: [NSNumber])
    {
        log.debug("Writing packets.")
        packetFlow.writePackets(packetDatas, withProtocols: protocolNumbers)
    }
    
    /// Handle IPC messages from the app.
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
    {
        switch connectionAttemptStatus
        {
            case .initialized:
                log.debug("handleAppMessage called before start tunnel. Doing nothing...")
            case .started:
                log.debug("Connection attempt started.")
            case .connecting:
                break
            case .connected:
                log.debug("### Connection is connected ###")
            case .ipAssigned( _):
                log.debug("Received IP assignment from the server.")
            case .ready:
                log.debug("!!! Connection is ready !!!")
            case .stillReady:
                break
            case .failed:
                log.debug("~~~ Connection failed ~~~")
        }
        
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
    
    open func closeTunnelWithError(_ error: Error?)
    {
        log.error("Closing the tunnel with error: \(String(describing: error))")
        lastError = error
        pendingStartCompletion?(error)
        
        // Close the tunnel connection.
        if let TCPConnection = connection
        {
            TCPConnection.cancel()
        }
        
        tunnelConnection = nil
        connectionAttemptStatus = .initialized
    }
    
    /// Handle the event of the tunnel connection being closed.
    func tunnelDidClose()
    {
        if pendingStartCompletion != nil
        {
            // Closed while starting, call the start completion handler with the appropriate error.
            pendingStartCompletion?(lastError)
            pendingStartCompletion = nil
        }
        else if pendingStopCompletion != nil
        {
            // Closed as the result of a call to stopTunnelWithReason, call the stop completion handler.
            pendingStopCompletion?()
            pendingStopCompletion = nil
        }
        else
        {
            // Closed as the result of an error on the tunnel connection, cancel the tunnel.
            cancelTunnelWithError(lastError)
        }
    }
    
    // MARK: - ClientTunnelConnection
    
    /// Handle the event of the logical flow of packets being established through the tunnel.
    func setTunnelSettings(tunnelAddress: TunnelAddress)
    {
        log.debug("🚀 setTunnelSettings  🚀")
        
        guard let host = remoteHost
        else
        {
            log.error("Unable to set network settings remote host is nil.")
            connectionAttemptStatus = .initialized
            pendingStartCompletion?(TunnelError.internalError)
            pendingStartCompletion = nil
            return
        }
        
        connectionAttemptStatus = .ipAssigned(tunnelAddress)
        
        let settings = makeNetworkSettings(host: host, tunnelAddress: tunnelAddress)
        
        // Set the virtual interface settings.
        setTunnelNetworkSettings(settings, completionHandler: tunnelSettingsCompleted)
    }
    
    func tunnelSettingsCompleted(maybeError: Error?)
    {
        log.debug("Tunnel settings updated.")
        
        if let error = maybeError
        {
            self.log.error("Failed to set the tunnel network settings: \(error)")
            failedConnection(error: error)
            return
        }

        guard let startCompletion = pendingStartCompletion
        else
        {
            failedConnection(error: TunnelError.internalError)
            return
        }
        
        connectionAttemptStatus = .ready
        startCompletion(nil)
        
        let newConnection = ClientTunnelConnection(clientPacketFlow: self.packetFlow, replicantConnection: connection!, logger: log)

        self.log.debug("\n🚀 Connection to server complete! 🚀\n")
        self.tunnelConnection = newConnection
        newConnection.startHandlingPackets()
    }
    
    func connectToServer()
    {
        connectionAttemptStatus = .connecting
        
        log.debug("Connect to server called.")
        guard let replicantConnectionFactory = replicantConnectionFactory
            else
        {
            log.error("Unable to find connection factory.")
            return
        }
        
        let parameters = NWParameters.tcp
        let connectQueue = DispatchQueue(label: "connectQueue")
        
        guard let replicantConnection = replicantConnectionFactory.connect(using: parameters) as? ReplicantConnection
            else
        {
            log.error("🥀  Replicant Factory failed to create a connection. 🥀")
            return
        }
        
        connection = replicantConnection
        
        // Kick off the connection to the server
        log.debug("⚽️ Kicking off the connection to the server.")
        connection!.stateUpdateHandler = handleStateUpdate
        connection!.start(queue: connectQueue)
    }
    
    func waitForIPAssignment()
    {
        guard let currentConnection = connection
        else
        {
            failedConnection(error: TunnelError.disconnected)
            
            return
        }
        
        currentConnection.readMessage
        {
            (message) in
            
            switch message
            {
                case .IPAssignV4(let ipv4Address):
                    self.setTunnelSettings(tunnelAddress: .ipV4(ipv4Address))
                case .IPAssignV6(let ipv6Address):
                    self.setTunnelSettings(tunnelAddress: .ipV6(ipv6Address))
                case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                    self.setTunnelSettings(tunnelAddress: .dualStack(ipv4Address, ipv6Address))
                default:
                    self.waitForIPAssignment()
            }
        }
    }
    
    func handleStateUpdate(newState: NWConnection.State)
    {
        self.log.debug("CURRENT STATE = \(newState)")
        
        guard let startCompletion = pendingStartCompletion
            else
        {
            log.error("pendingStartCompletion is nil?")
            return
        }
        
        switch newState
        {
            case .preparing:
                self.log.debug("\n⏳ Connection is  preparing ⏳\n")
                isConnected = ConnectState(state: .start, stage: .statusCodes)
                
            case .setup:
                self.log.debug("\n👷‍♀️ Connection is in the setup stage 👷‍♀️\n")
                isConnected = ConnectState(state: .trying, stage: .statusCodes)
                
            case .ready:
                // Start reading messages from the tunnel connection.
                // Open the logical flow of packets through the tunnel.
                guard connection != nil
                    else
                {
                    log.error("Ready state but replicant connection is nil.")
                    return
                }
                
                self.log.debug("\n🌲 Connection state is ready 🌲\n")
                isConnected = ConnectState(state: .success, stage: .statusCodes)
                waitForIPAssignment()
                
            case .cancelled:
                self.log.debug("\n🙅‍♀️  Connection Cancelled  🙅‍♀️\n")
                self.connection = nil
                self.tunnelDidClose()
                connectionAttemptStatus = .failed
                startCompletion(TunnelError.cancelled)
                
            case .failed(let error):
                self.log.error("\n🐒  Connection Failed  🐒\n")
                self.closeTunnelWithError(error)
                connectionAttemptStatus = .failed
                startCompletion(error)
                
            default:
                self.log.debug("\n🤷‍♀️  Unexpected State: \(newState) 🤷‍♀️\n")
        }
    }
    
    func failedConnection(error: Error)
    {
        connectionAttemptStatus = .failed
        
        if let completionHandler = pendingStartCompletion
        {
            completionHandler(error)
            pendingStartCompletion = nil
        }
    }
}

enum ConnectionAttemptStatus
{
    case initialized // Start tunnel has not been called yet
    case started // Start tunnel has been called but nothing has been done yet
    case connecting // Tried to connect to the server but have not heard back yet
    case connected // Connected to the server
    case ipAssigned(TunnelAddress) // Received an IP assignment message from the server
    case ready // Connected and able to received packets (handshakes etc. are complete)
    case stillReady // ??
    case failed // Failed :(
}

public enum TunnelError: Error
{
    case badConfiguration
    case badConnection
    case cancelled
    case disconnected
    case internalError
}

public enum TunnelAddress
{
    case ipV4(IPv4Address)
    case ipV6(IPv6Address)
    case dualStack(IPv4Address, IPv6Address)
}
