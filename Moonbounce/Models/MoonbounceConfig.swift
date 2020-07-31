//
//  MoonbounceConfig.swift
//  Moonbounce.iOS
//
//  Created by Mafalda on 1/18/19.
//  Copyright © 2019 Operator Foundation. All rights reserved.
//

import Foundation
import ReplicantSwift
import Network
import NetworkExtension

class MoonbounceConfig: NSObject
{
    static let filenameExtension = "moonbounce"
    
    let fileManager = FileManager.default
    let replicantConfig: ReplicantConfig<SilverClientConfig>?
    let clientConfig: ClientConfig
    var name: String

    init(name: String, clientConfig: ClientConfig, replicantConfig: ReplicantConfig<SilverClientConfig>?)
    {
        self.name = name
        self.clientConfig = clientConfig
        self.replicantConfig = replicantConfig
    }
}

enum DocumentError: Error
{
    case unrecognizedContent
    case corruptDocument
    case archivingFailure
    
    var localizedDescription: String
    {
        switch self
        {
            
        case .unrecognizedContent:
            return NSLocalizedString("File is an unrecognised format", comment: "")
        case .corruptDocument:
            return NSLocalizedString("File could not be read", comment: "")
        case .archivingFailure:
            return NSLocalizedString("File could not be saved", comment: "")
        }
    }
    
}
