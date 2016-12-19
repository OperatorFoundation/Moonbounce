//
//  Globals.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation

var helperClient:MoonbounceHelperProtocol?
let kOutputTextNotification: CFString = "OutputFromBashNotification" as CFString
var connectionStatus: Status = .disconnected

enum Status
{
    case connected
    case connecting
    case disconnected
}
