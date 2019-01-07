// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation

extension TunnelConfiguration {

    enum ParserState {
        case inInterfaceSection
        case inPeerSection
        case notInASection
    }

    enum ParseError: Error {
        case invalidLine(_ line: String.SubSequence)
        case noInterface
        case invalidInterface
        case multipleInterfaces
        case multiplePeersWithSamePublicKey
        case invalidPeer
    }

    //swiftlint:disable:next function_body_length cyclomatic_complexity
    convenience init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        var interfaceConfiguration: InterfaceConfiguration?
        var peerConfigurations = [PeerConfiguration]()

        let lines = wgQuickConfig.split(separator: "\n")

        var parserState = ParserState.notInASection
        var attributes = [String: String]()

        for (lineIndex, line) in lines.enumerated() {
            var trimmedLine: String
            if let commentRange = line.range(of: "#") {
                trimmedLine = String(line[..<commentRange.lowerBound])
            } else {
                trimmedLine = String(line)
            }

            trimmedLine = trimmedLine.trimmingCharacters(in: .whitespaces)

            guard !trimmedLine.isEmpty else { continue }
            let lowercasedLine = line.lowercased()

            if let equalsIndex = line.firstIndex(of: "=") {
                // Line contains an attribute
                let key = line[..<equalsIndex].trimmingCharacters(in: .whitespaces).lowercased()
                let value = line[line.index(equalsIndex, offsetBy: 1)...].trimmingCharacters(in: .whitespaces)
                let keysWithMultipleEntriesAllowed: Set<String> = ["address", "allowedips", "dns"]
                if let presentValue = attributes[key], keysWithMultipleEntriesAllowed.contains(key) {
                    attributes[key] = presentValue + "," + value
                } else {
                    attributes[key] = value
                }
            } else if lowercasedLine != "[interface]" && lowercasedLine != "[peer]" {
                throw ParseError.invalidLine(line)
            }

            let isLastLine = lineIndex == lines.count - 1

            if isLastLine || lowercasedLine == "[interface]" || lowercasedLine == "[peer]" {
                // Previous section has ended; process the attributes collected so far
                if parserState == .inInterfaceSection {
                    guard let interface = TunnelConfiguration.collate(interfaceAttributes: attributes) else { throw ParseError.invalidInterface }
                    guard interfaceConfiguration == nil else { throw ParseError.multipleInterfaces }
                    interfaceConfiguration = interface
                } else if parserState == .inPeerSection {
                    guard let peer = TunnelConfiguration.collate(peerAttributes: attributes) else { throw ParseError.invalidPeer }
                    peerConfigurations.append(peer)
                }
            }

            if lowercasedLine == "[interface]" {
                parserState = .inInterfaceSection
                attributes.removeAll()
            } else if lowercasedLine == "[peer]" {
                parserState = .inPeerSection
                attributes.removeAll()
            }
        }

        let peerPublicKeysArray = peerConfigurations.map { $0.publicKey }
        let peerPublicKeysSet = Set<Data>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            throw ParseError.multiplePeersWithSamePublicKey
        }

        if let interfaceConfiguration = interfaceConfiguration {
            self.init(name: name, interface: interfaceConfiguration, peers: peerConfigurations)
        } else {
            throw ParseError.noInterface
        }
    }

    func asWgQuickConfig() -> String {
        var output = "[Interface]\n"
        output.append("PrivateKey = \(interface.privateKey.base64EncodedString())\n")
        if let listenPort = interface.listenPort {
            output.append("ListenPort = \(listenPort)\n")
        }
        if !interface.addresses.isEmpty {
            let addressString = interface.addresses.map { $0.stringRepresentation }.joined(separator: ", ")
            output.append("Address = \(addressString)\n")
        }
        if !interface.dns.isEmpty {
            let dnsString = interface.dns.map { $0.stringRepresentation }.joined(separator: ", ")
            output.append("DNS = \(dnsString)\n")
        }
        if let mtu = interface.mtu {
            output.append("MTU = \(mtu)\n")
        }

        for peer in peers {
            output.append("\n[Peer]\n")
            output.append("PublicKey = \(peer.publicKey.base64EncodedString())\n")
            if let preSharedKey = peer.preSharedKey {
                output.append("PresharedKey = \(preSharedKey.base64EncodedString())\n")
            }
            if !peer.allowedIPs.isEmpty {
                let allowedIPsString = peer.allowedIPs.map { $0.stringRepresentation }.joined(separator: ", ")
                output.append("AllowedIPs = \(allowedIPsString)\n")
            }
            if let endpoint = peer.endpoint {
                output.append("Endpoint = \(endpoint.stringRepresentation)\n")
            }
            if let persistentKeepAlive = peer.persistentKeepAlive {
                output.append("PersistentKeepalive = \(persistentKeepAlive)\n")
            }
        }

        return output
    }

    //swiftlint:disable:next cyclomatic_complexity
    private static func collate(interfaceAttributes attributes: [String: String]) -> InterfaceConfiguration? {
        // required wg fields
        guard let privateKeyString = attributes["privatekey"] else { return nil }
        guard let privateKey = Data(base64Encoded: privateKeyString), privateKey.count == TunnelConfiguration.keyLength else { return nil }
        var interface = InterfaceConfiguration(privateKey: privateKey)
        // other wg fields
        if let listenPortString = attributes["listenport"] {
            guard let listenPort = UInt16(listenPortString) else { return nil }
            interface.listenPort = listenPort
        }
        // wg-quick fields
        if let addressesString = attributes["address"] {
            var addresses = [IPAddressRange]()
            for addressString in addressesString.splitToArray(trimmingCharacters: .whitespaces) {
                guard let address = IPAddressRange(from: addressString) else { return nil }
                addresses.append(address)
            }
            interface.addresses = addresses
        }
        if let dnsString = attributes["dns"] {
            var dnsServers = [DNSServer]()
            for dnsServerString in dnsString.splitToArray(trimmingCharacters: .whitespaces) {
                guard let dnsServer = DNSServer(from: dnsServerString) else { return nil }
                dnsServers.append(dnsServer)
            }
            interface.dns = dnsServers
        }
        if let mtuString = attributes["mtu"] {
            guard let mtu = UInt16(mtuString) else { return nil }
            interface.mtu = mtu
        }
        return interface
    }

    //swiftlint:disable:next cyclomatic_complexity
    private static func collate(peerAttributes attributes: [String: String]) -> PeerConfiguration? {
        // required wg fields
        guard let publicKeyString = attributes["publickey"] else { return nil }
        guard let publicKey = Data(base64Encoded: publicKeyString), publicKey.count == TunnelConfiguration.keyLength else { return nil }
        var peer = PeerConfiguration(publicKey: publicKey)
        // wg fields
        if let preSharedKeyString = attributes["presharedkey"] {
            guard let preSharedKey = Data(base64Encoded: preSharedKeyString), preSharedKey.count == TunnelConfiguration.keyLength else { return nil }
            peer.preSharedKey = preSharedKey
        }
        if let allowedIPsString = attributes["allowedips"] {
            var allowedIPs = [IPAddressRange]()
            for allowedIPString in allowedIPsString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                guard let allowedIP = IPAddressRange(from: allowedIPString) else { return nil }
                allowedIPs.append(allowedIP)
            }
            peer.allowedIPs = allowedIPs
        }
        if let endpointString = attributes["endpoint"] {
            guard let endpoint = Endpoint(from: endpointString) else { return nil }
            peer.endpoint = endpoint
        }
        if let persistentKeepAliveString = attributes["persistentkeepalive"] {
            guard let persistentKeepAlive = UInt16(persistentKeepAliveString) else { return nil }
            peer.persistentKeepAlive = persistentKeepAlive
        }
        return peer
    }

}
