//
//  NEVPNStatus+Extension.swift
//  Moonbounce
//
//  Created by Mafalda on 4/13/20.
//  Copyright © 2020 operatorfoundation.org. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEVPNStatus
{
    var stringValue: String {
        switch self {
        case .invalid:
            return "invalid"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        case .disconnected:
            return "disconnected"
        case .reasserting:
            return "reasserting"
        default:
            return "unknown"
        }
    }
}
