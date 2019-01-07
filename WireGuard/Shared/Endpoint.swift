// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import Foundation
import Network

struct Endpoint {
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port

    init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.host = host
        self.port = port
    }
}

extension Endpoint: Equatable {
    static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        return lhs.host == rhs.host && lhs.port == rhs.port
    }
}

extension Endpoint: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(host)
        hasher.combine(port)
    }
}

extension Endpoint {
    var stringRepresentation: String {
        switch host {
        case .name(let hostname, _):
            return "\(hostname):\(port)"
        case .ipv4(let address):
            return "\(address):\(port)"
        case .ipv6(let address):
            return "[\(address)]:\(port)"
        }
    }

    init?(from string: String) {
        // Separation of host and port is based on 'parse_endpoint' function in
        // https://git.zx2c4.com/WireGuard/tree/src/tools/config.c
        guard !string.isEmpty else { return nil }
        let startOfPort: String.Index
        let hostString: String
        if string.first! == "[" {
            // Look for IPv6-style endpoint, like [::1]:80
            let startOfHost = string.index(after: string.startIndex)
            guard let endOfHost = string.dropFirst().firstIndex(of: "]") else { return nil }
            let afterEndOfHost = string.index(after: endOfHost)
            guard string[afterEndOfHost] == ":" else { return nil }
            startOfPort = string.index(after: afterEndOfHost)
            hostString = String(string[startOfHost ..< endOfHost])
        } else {
            // Look for an IPv4-style endpoint, like 127.0.0.1:80
            guard let endOfHost = string.firstIndex(of: ":") else { return nil }
            startOfPort = string.index(after: endOfHost)
            hostString = String(string[string.startIndex ..< endOfHost])
        }
        guard let endpointPort = NWEndpoint.Port(String(string[startOfPort ..< string.endIndex])) else { return nil }
        let invalidCharacterIndex = hostString.unicodeScalars.firstIndex { char in
            return !CharacterSet.urlHostAllowed.contains(char)
        }
        guard invalidCharacterIndex == nil else { return nil }
        host = NWEndpoint.Host(hostString)
        port = endpointPort
    }
}

extension Endpoint {
    func hasHostAsIPAddress() -> Bool {
        switch host {
        case .name:
            return false
        case .ipv4:
            return true
        case .ipv6:
            return true
        }
    }

    func hostname() -> String? {
        switch host {
        case .name(let hostname, _):
            return hostname
        case .ipv4:
            return nil
        case .ipv6:
            return nil
        }
    }
}
