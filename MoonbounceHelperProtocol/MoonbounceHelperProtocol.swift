//
//  MoonbounceHelperProtocol.swift
//  Moonbounce
//
//  Created by Adelita Schule on 12/5/16.
//  Copyright © 2016 operatorfoundation.org. All rights reserved.
//

import Foundation
@objc(MoonbounceHelperProtocol)
protocol MoonbounceHelperProtocol
{
    func startOpenVPN(openVPNFilePath: String, configFileName: String)
    func stopOpenVPN()
}
