// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import NetworkExtension
import os.log

protocol TunnelsManagerListDelegate: class
{
    func tunnelAdded(at index: Int)
    func tunnelModified(at index: Int)
    func tunnelMoved(from oldIndex: Int, to newIndex: Int)
    func tunnelRemoved(at index: Int)
}

protocol TunnelsManagerActivationDelegate: class
{
    func tunnelActivationAttemptFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationAttemptError) // startTunnel wasn't called or failed
    func tunnelActivationAttemptSucceeded(tunnel: TunnelContainer) // startTunnel succeeded
    func tunnelActivationFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationError) // status didn't change to connected
    func tunnelActivationSucceeded(tunnel: TunnelContainer) // status changed to connected
}

class TunnelsManager
{
    private var tunnels: [TunnelContainer]
    weak var tunnelsListDelegate: TunnelsManagerListDelegate?
    weak var activationDelegate: TunnelsManagerActivationDelegate?
    private var statusObservationToken: AnyObject?
    private var waiteeObservationToken: AnyObject?
    

    init(tunnelProviders: [NETunnelProviderManager])
    {
        var unsortedTunnels = [TunnelContainer]()
        
        for tunnelProviderManager in tunnelProviders
        {
            if let tunnel = TunnelContainer(tunnel: tunnelProviderManager)
            {
                unsortedTunnels.append(tunnel)
            }
        }
        
        tunnels = unsortedTunnels.sorted { $0.name < $1.name }
        startObservingTunnelStatuses()
    }

    static func create(completionHandler: @escaping (WireGuardResult<TunnelsManager>) -> Void)
    {
        #if targetEnvironment(simulator)
        completionHandler(.success(TunnelsManager(tunnelProviders: MockTunnels.createMockTunnels())))
        #else
        
        // TODO:
        NETunnelProviderManager.loadAllFromPreferences
        {
            managers, error in
            
            if let error = error
            {
                wg_log(.error, message: "Failed to load tunnel provider managers: \(error)")
                completionHandler(.failure(TunnelsManagerError.systemErrorOnListingTunnels(systemError: error)))
                return
            }
            
            guard let tunnelManagers = managers
            else
            {
                completionHandler(.failure(TunnelsManagerError.errorOnListingTunnels))
                return
            }

            completionHandler(.success(TunnelsManager(tunnelProviders: tunnelManagers)))
        }
        #endif
    }

    func reload(completionHandler: @escaping (Bool) -> Void)
    {
        #if targetEnvironment(simulator)
        completionHandler(false)
        #else
        NETunnelProviderManager.loadAllFromPreferences
        {
            managers, _ in
            
            var newTunnels = [TunnelContainer]()
            
            guard let managers = managers
            else
            {
                completionHandler(false)
                return
            }

            for manager in managers
            {
                if let newTunnel = TunnelContainer(tunnel: manager)
                {
                    newTunnels.append(newTunnel)
                }
            }
            
            newTunnels = newTunnels.sorted { $0.name < $1.name }
            
            let hasChanges = self.tunnels.map { $0.tunnelConfiguration } != newTunnels.map { $0.tunnelConfiguration }
            if hasChanges
            {
                self.tunnels = newTunnels
                completionHandler(true)
            }
            else
            {
                completionHandler(false)
            }
        }
        #endif
    }

    func add(tunnelConfiguration: TunnelConfiguration, activateOnDemandSetting: ActivateOnDemandSetting = ActivateOnDemandSetting.defaultSetting, completionHandler: @escaping (WireGuardResult<TunnelContainer>) -> Void)
    {
        let tunnelName = tunnelConfiguration.name ?? ""
        if tunnelName.isEmpty
        {
            completionHandler(.failure(TunnelsManagerError.tunnelNameEmpty))
            return
        }

        if tunnels.contains(where: { $0.name == tunnelName })
        {
            completionHandler(.failure(TunnelsManagerError.tunnelAlreadyExistsWithThatName))
            return
        }

        // MARK: - This is where we pass our parameters to the extension
        let appId = Bundle.main.bundleIdentifier!
        let tunnelProviderManager = NETunnelProviderManager()
        let tunnelProviderProtocol = tunnelConfiguration.tunnelProviderProtocol
        
        tunnelProviderProtocol.providerBundleIdentifier = "\(appId).NetworkExtension"
        print("\n\(String(describing: tunnelProviderProtocol.providerConfiguration))\n")
        tunnelProviderManager.protocolConfiguration = tunnelProviderProtocol
        tunnelProviderManager.localizedDescription = tunnelConfiguration.name
        tunnelProviderManager.isEnabled = true
        
        activateOnDemandSetting.apply(on: tunnelProviderManager)
        
        guard let tunnel = TunnelContainer(tunnel: tunnelProviderManager)
        else
        {
            completionHandler(.failure(TunnelsManagerError.errorOnListingTunnels))
            return
        }
        
        self.tunnels.append(tunnel)
        self.tunnels.sort { $0.name < $1.name }
        self.tunnelsListDelegate?.tunnelAdded(at: self.tunnels.firstIndex(of: tunnel)!)

        tunnelProviderManager.loadFromPreferences
        {
            maybeError in
            
            guard maybeError == nil
            else
            {
                wg_log(.error, message: "startActivation: Error reloading tunnel: \(maybeError!)")
                completionHandler(.failure(TunnelsManagerError.systemErrorOnAddTunnel(systemError: maybeError!)))
                return
            }
            
            tunnelProviderManager.saveToPreferences
            {
                maybeError in
                
                guard maybeError == nil
                    else
                {
                    wg_log(.error, message: "Add: Saving configuration failed: \(maybeError!)")
                    completionHandler(.failure(TunnelsManagerError.systemErrorOnAddTunnel(systemError: maybeError!)))
                    return
                }
                
                completionHandler(.success(tunnel))
                
//                tunnelProviderManager.saveToPreferences
//                {
//                    maybeError in
//
//                    guard maybeError == nil
//                        else
//                    {
//                        wg_log(.error, message: "Add: Saving configuration failed: \(maybeError!)")
//                        completionHandler(.failure(TunnelsManagerError.systemErrorOnAddTunnel(systemError: maybeError!)))
//                        return
//                    }
//
//                    completionHandler(.success(tunnel))
//                }
            }
        }
    }

    func addMultiple(tunnelConfigurations: [TunnelConfiguration], completionHandler: @escaping (UInt) -> Void) {
        addMultiple(tunnelConfigurations: ArraySlice(tunnelConfigurations), numberSuccessful: 0, completionHandler: completionHandler)
    }

    private func addMultiple(tunnelConfigurations: ArraySlice<TunnelConfiguration>, numberSuccessful: UInt, completionHandler: @escaping (UInt) -> Void) {
        guard let head = tunnelConfigurations.first else {
            completionHandler(numberSuccessful)
            return
        }
        let tail = tunnelConfigurations.dropFirst()
        add(tunnelConfiguration: head)
        {
            [weak self, tail] result in
            
            DispatchQueue.main.async {
                self?.addMultiple(tunnelConfigurations: tail, numberSuccessful: numberSuccessful + (result.isSuccess ? 1 : 0), completionHandler: completionHandler)
            }
        }
    }

    func modify(tunnel: TunnelContainer, tunnelConfiguration: TunnelConfiguration, activateOnDemandSetting: ActivateOnDemandSetting, completionHandler: @escaping (TunnelsManagerError?) -> Void)
    {
        let tunnelName = tunnelConfiguration.name ?? ""
        if tunnelName.isEmpty
        {
            completionHandler(TunnelsManagerError.tunnelNameEmpty)
            return
        }

        let tunnelProviderManager = tunnel.tunnelProvider
        let isNameChanged = tunnelName != tunnelProviderManager.localizedDescription
        if isNameChanged
        {
            guard !tunnels.contains(where: { $0.name == tunnelName })
                else
            {
                completionHandler(TunnelsManagerError.tunnelAlreadyExistsWithThatName)
                return
            }
            tunnel.name = tunnelName
        }

        tunnelProviderManager.protocolConfiguration = tunnelConfiguration.tunnelProviderProtocol
        tunnelProviderManager.localizedDescription = tunnelConfiguration.name
        tunnelProviderManager.isEnabled = true

        let isActivatingOnDemand = !tunnelProviderManager.isOnDemandEnabled && activateOnDemandSetting.isActivateOnDemandEnabled
        activateOnDemandSetting.apply(on: tunnelProviderManager)

        tunnelProviderManager.saveToPreferences
        {
            [weak self] error in
            
            guard error == nil
                else
            {
                wg_log(.error, message: "Modify: Saving configuration failed: \(error!)")
                completionHandler(TunnelsManagerError.systemErrorOnModifyTunnel(systemError: error!))
                return
            }
            
            guard let self = self
                else { return }

            if isNameChanged
            {
                let oldIndex = self.tunnels.firstIndex(of: tunnel)!
                self.tunnels.sort { $0.name < $1.name }
                let newIndex = self.tunnels.firstIndex(of: tunnel)!
                self.tunnelsListDelegate?.tunnelMoved(from: oldIndex, to: newIndex)
            }
            self.tunnelsListDelegate?.tunnelModified(at: self.tunnels.firstIndex(of: tunnel)!)

            if tunnel.status == .active || tunnel.status == .activating || tunnel.status == .reasserting
            {
                // Turn off the tunnel, and then turn it back on, so the changes are made effective
                tunnel.status = .restarting
                (tunnel.tunnelProvider.connection as? NETunnelProviderSession)?.stopTunnel()
            }

            if isActivatingOnDemand
            {
                // Reload tunnel after saving.
                // Without this, the tunnel stopes getting updates on the tunnel status from iOS.
                tunnelProviderManager.loadFromPreferences
                {
                    error in
                    
                    tunnel.isActivateOnDemandEnabled = tunnelProviderManager.isOnDemandEnabled
                    guard error == nil
                        else
                    {
                        wg_log(.error, message: "Modify: Re-loading after saving configuration failed: \(error!)")
                        completionHandler(TunnelsManagerError.systemErrorOnModifyTunnel(systemError: error!))
                        return
                    }
                    
                    completionHandler(nil)
                }
            }
            else
            {
                completionHandler(nil)
            }
        }
    }

    func remove(tunnel: TunnelContainer, completionHandler: @escaping (TunnelsManagerError?) -> Void) {
        let tunnelProviderManager = tunnel.tunnelProvider

        tunnelProviderManager.removeFromPreferences { [weak self] error in
            guard error == nil else {
                wg_log(.error, message: "Remove: Saving configuration failed: \(error!)")
                completionHandler(TunnelsManagerError.systemErrorOnRemoveTunnel(systemError: error!))
                return
            }
            if let self = self {
                let index = self.tunnels.firstIndex(of: tunnel)!
                self.tunnels.remove(at: index)
                self.tunnelsListDelegate?.tunnelRemoved(at: index)
            }
            completionHandler(nil)
        }
    }

    func numberOfTunnels() -> Int {
        return tunnels.count
    }

    func tunnel(at index: Int) -> TunnelContainer {
        return tunnels[index]
    }

    func tunnel(named tunnelName: String) -> TunnelContainer? {
        return tunnels.first { $0.name == tunnelName }
    }

    func startActivation(of tunnel: TunnelContainer)
    {
        guard tunnels.contains(tunnel)
            else { return } // Ensure it's not deleted
        
        guard tunnel.status == .inactive
            else
        {
            activationDelegate?.tunnelActivationAttemptFailed(tunnel: tunnel, error: .tunnelIsNotInactive)
            return
        }

        if let alreadyWaitingTunnel = tunnels.first(where: { $0.status == .waiting })
        {
            alreadyWaitingTunnel.status = .inactive
        }

        if let tunnelInOperation = tunnels.first(where: { $0.status != .inactive })
        {
            wg_log(.info, message: "Tunnel '\(tunnel.name)' waiting for deactivation of '\(tunnelInOperation.name)'")
            tunnel.status = .waiting
            activateWaitingTunnelOnDeactivation(of: tunnelInOperation)
            if tunnelInOperation.status != .deactivating {
                startDeactivation(of: tunnelInOperation)
            }
            return
        }

        #if targetEnvironment(simulator)
        tunnel.status = .active
        #else
        tunnel.startActivation(activationDelegate: activationDelegate)
        #endif
    }

    func startDeactivation(of tunnel: TunnelContainer)
    {
        tunnel.isAttemptingActivation = false
        
        guard tunnel.status != .inactive && tunnel.status != .deactivating
            else { return }
        
        #if targetEnvironment(simulator)
        tunnel.status = .inactive
        #else
        tunnel.startDeactivation()
        #endif
    }

    func refreshStatuses()
    {
        tunnels.forEach { $0.refreshStatus() }
    }

    private func activateWaitingTunnelOnDeactivation(of tunnel: TunnelContainer)
    {
        waiteeObservationToken = tunnel.observe(\.status)
        {
            [weak self] tunnel, _ in
            
            guard let self = self
                else { return }
            
            if tunnel.status == .inactive
            {
                if let waitingTunnel = self.tunnels.first(where: { $0.status == .waiting })
                {
                    waitingTunnel.startActivation(activationDelegate: self.activationDelegate)
                }
                
                self.waiteeObservationToken = nil
            }
        }
    }

    private func startObservingTunnelStatuses()
    {
        statusObservationToken = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: OperationQueue.main)
        {
            [weak self] statusChangeNotification in
            
            guard let self = self,
                let session = statusChangeNotification.object as? NETunnelProviderSession
            else
            {
                return
            }
            
            print("\nSession Status = \(session.status)\n")

            guard let tunnelProvider = session.manager as? NETunnelProviderManager,
            let tunnelConfiguration = TunnelContainer(tunnel: tunnelProvider)?.tunnelConfiguration,
            let tunnel = self.tunnels.first(where: { $0.tunnelConfiguration == tunnelConfiguration })
            else { return }
            
            if tunnel.tunnelProvider != tunnelProvider
            {
                tunnel.tunnelProvider = tunnelProvider
                tunnel.refreshStatus()
            }

            wg_log(.debug, message: "Tunnel '\(tunnel.name)' connection status changed to '\(tunnel.tunnelProvider.connection.status)'")

            if tunnel.isAttemptingActivation
            {
                if session.status == .connected
                {
                    tunnel.isAttemptingActivation = false
                    self.activationDelegate?.tunnelActivationSucceeded(tunnel: tunnel)
                }
                else if session.status == .disconnected
                {
                    tunnel.isAttemptingActivation = false
                    if let (title, message) = lastErrorTextFromNetworkExtension(for: tunnel)
                    {
                        self.activationDelegate?.tunnelActivationFailed(tunnel: tunnel, error: .activationFailedWithExtensionError(title: title, message: message, wasOnDemandEnabled: tunnelProvider.isOnDemandEnabled))
                    }
                    else
                    {
                        self.activationDelegate?.tunnelActivationFailed(tunnel: tunnel, error: .activationFailed(wasOnDemandEnabled: tunnelProvider.isOnDemandEnabled))
                    }
                }
            }

            if (tunnel.status == .restarting) && (session.status == .disconnected || session.status == .disconnecting)
            {
                if session.status == .disconnected
                {
                    tunnel.startActivation(activationDelegate: self.activationDelegate)
                }
                
                return
            }

            tunnel.refreshStatus()
        }
    }

}

private func lastErrorTextFromNetworkExtension(for tunnel: TunnelContainer) -> (title: String, message: String)?
{
    guard let lastErrorFileURL = FileManager.networkExtensionLastErrorFileURL
        else { return nil }
    guard let lastErrorData = try? Data(contentsOf: lastErrorFileURL)
        else { return nil }
    guard let lastErrorStrings = String(data: lastErrorData, encoding: .utf8)?.splitToArray(separator: "\n")
        else { return nil }
    guard lastErrorStrings.count == 2 && tunnel.activationAttemptId == lastErrorStrings[0]
        else { return nil }

    if let extensionError = PacketTunnelProviderError(rawValue: lastErrorStrings[1])
    {
        return extensionError.alertText
    }

    return ("alertTunnelActivationFailureTitle", "alertTunnelActivationFailureMessage")
}

