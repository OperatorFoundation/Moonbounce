//
//  DebugPacketTunnelProvider.swift
//  MoonbounceNetworkExtension
//
//  Created by Dr. Brandon Wiley on 6/1/22.
//  Copyright © 2022 operatorfoundation.org. All rights reserved.
//

//import Foundation
//import Logging
//import NetworkExtension
//import Datable
//
//// FIXME - for testing, remove
//class MoonbounceNetworkExtensionPacketTunnelProvider: NEPacketTunnelProvider
//{
//    var logger: Logger!
//    var connection: NWTCPConnection! = nil
//
//    public override init()
//    {
//        self.logger = Logger(label: "MoonbounceNetworkExtension")
//        self.logger.logLevel = .debug
//
//        self.logger.debug("Initialized MoonbouncePacketTunnelProvider")
//        self.logger.debug("MoonbouncePacketTunnelProvider.init")
//
//        super.init()
//    }
//
//    // NEPacketTunnelProvider
//    public override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void)
//    {
//        self.logger.debug("MoonbouncePacketTunnelProvider.startTunnel")
//
//        // FIXME - remove, just for testing
//        completionHandler(nil)
//
//        //        self.neModule.startTunnel(events: self.simulation.events, options: options, completionHandler: completionHandler)        completionHandler(nil)
//
//        self.connection = self.createTCPConnection(to: NWHostEndpoint(hostname: "206.189.200.18", port: "8888"), enableTLS: false, tlsParameters: nil, delegate: nil)
//        self.connection.write("WOOOOOO".data)
//        {
//            maybeError in
//
//            self.logger.log(level: .debug, "YEEEEEAAAHHH")
//        }
//    }
//
//    public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void)
//    {
//        self.logger.debug("MoonbouncePacketTunnelProvider.stopTunnel")
//        completionHandler()
//    }
//
//    /// Handle IPC messages from the app.
//    public override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?)
//    {
//        self.logger.debug("MoonbouncePacketTunnelProvider.handleAppMessage")
//        if let handler = completionHandler
//        {
//            handler(nil)
//        }
//    }
//
//    open override func cancelTunnelWithError(_ error: Error?)
//    {
//        self.logger.debug("MoonbouncePacketTunnelProvider.cancelTunnelWithError")
//        logger.error("Closing the tunnel with error: \(String(describing: error))")
//        self.stopTunnel(with: NEProviderStopReason.userInitiated)
//        {
//            return
//        }
//    }
//    // End NEPacketTunnelProvider
//}
