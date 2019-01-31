//
//  PacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Adelita Schule on 1/3/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import NetworkExtension
import Network
import os.log
import Replicant
import ReplicantSwift
import Flow

class PacketTunnelProvider: NEPacketTunnelProvider
{
    private var networkMonitor: NWPathMonitor?
    private var ifname: String?
    private var packetTunnelSettingsGenerator: PacketTunnelSettingsGenerator?
    
    var flowerController: FlowerController?
    
    deinit
    {
        networkMonitor?.cancel()
    }
    
    override func startTunnel(options: [String: NSObject]?, completionHandler startTunnelCompletionHandler: @escaping (Error?) -> Void)
    {
        let activationAttemptId = options?["activationAttemptId"] as? String
        let errorNotifier = ErrorNotifier(activationAttemptId: activationAttemptId)
        
        guard let tunnelProviderProtocol = protocolConfiguration as? NETunnelProviderProtocol
        else
        {
            errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            startTunnelCompletionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        guard let tunnelConfiguration = tunnelProviderProtocol.asTunnelConfiguration()
        else
        {
            errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            startTunnelCompletionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        configureLogger()
        
        wg_log(.info, message: "Starting tunnel from the " + (activationAttemptId == nil ? "OS directly, rather than the app" : "app"))
       
        // Replicant
        guard let replicantConfig = tunnelConfiguration.replicantConfiguration
            else
        {
            print("\nUnable to parse Replicant config file.\n")
            return
        }
        
        // TODO: Replicant Server IP & Port come from ClientConfig
        
        guard let replicantPort = NWEndpoint.Port(rawValue: 51820)
            else
        {
            print("\nUnable to generate port for replicant connection.\n")
            return
        }
        
        let replicantServerIP = currentHost
        let replicantConnectionFactory = ReplicantConnectionFactory(host: replicantServerIP!, port: replicantPort, config: replicantConfig)
        
        guard let replicantConnection = replicantConnectionFactory.connect(using: .tcp)
            else
        {
            print("Unable to establish a Replicant connection.")
            return
        }
        
        // Flower
        
        flowerController = FlowerController(connection: replicantConnection)

        packetTunnelSettingsGenerator = PacketTunnelSettingsGenerator(tunnelConfiguration: tunnelConfiguration)
        
        setTunnelNetworkSettings(packetTunnelSettingsGenerator!.generateNetworkSettings())
        {
            error in
            
            if let error = error
            {
                wg_log(.error, message: "Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)")
                errorNotifier.notify(PacketTunnelProviderError.couldNotSetNetworkSettings)
                startTunnelCompletionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)
            }
            else
            {
                self.networkMonitor = NWPathMonitor()
                self.networkMonitor!.start(queue: DispatchQueue(label: "NetworkMonitor"))
                
                DispatchQueue.main.async
                {
                    startTunnelCompletionHandler(nil)
                    self.readPackets()
                }
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
    {
        networkMonitor?.cancel()
        networkMonitor = nil
        
        ErrorNotifier.removeLastErrorFile()
        
        wg_log(.info, staticMessage: "Stopping tunnel")
        
        // TODO: Stop the tunnel
        
        
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
    
    private func configureLogger()
    {
        Logger.configureGlobal(withFilePath: FileManager.networkExtensionLogFileURL?.path)
        
        // TODO: Replace wgSetLogger
//        wgSetLogger
//        {
//            level, msgC in
//
//            guard let msgC = msgC else { return }
//            let logType: OSLogType
//            switch level
//            {
//            case 0:
//                logType = .debug
//            case 1:
//                logType = .info
//            case 2:
//                logType = .error
//            default:
//                logType = .default
//            }
//            wg_log(logType, message: String(cString: msgC))
//        }
    }
    
}
