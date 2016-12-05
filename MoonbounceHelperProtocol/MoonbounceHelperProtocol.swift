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
    func startOpenVPN(appDirectory: String, configFileName: String, kextFilePath: String, completion:@escaping (_ launched:Bool) -> Void)
    func stopOpenVPN(kextFilePath: String)
}
