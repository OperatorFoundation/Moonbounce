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

class PacketTunnelProvider: NEPacketTunnelProvider
{
    private var networkMonitor: NWPathMonitor?
    private var ifname: String?
    private var packetTunnelSettingsGenerator: PacketTunnelSettingsGenerator?
    
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
       
        // TODO: Initialize Replicant Here
        
        
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
                
                let fileDescriptor = (self.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32) ?? -1
                if fileDescriptor < 0 {
                    wg_log(.error, staticMessage: "Starting tunnel failed: Could not determine file descriptor")
                    errorNotifier.notify(PacketTunnelProviderError.couldNotDetermineFileDescriptor)
                    startTunnelCompletionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)
                    return
                }
                
                var ifnameSize = socklen_t(IFNAMSIZ)
                let ifnamePtr = UnsafeMutablePointer<CChar>.allocate(capacity: Int(ifnameSize))
                ifnamePtr.initialize(repeating: 0, count: Int(ifnameSize))
                if getsockopt(fileDescriptor, 2 /* SYSPROTO_CONTROL */, 2 /* UTUN_OPT_IFNAME */, ifnamePtr, &ifnameSize) == 0 {
                    self.ifname = String(cString: ifnamePtr)
                }
                ifnamePtr.deallocate()
                wg_log(.info, message: "Tunnel interface is \(self.ifname ?? "unknown")")
                
                startTunnelCompletionHandler(nil)
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
