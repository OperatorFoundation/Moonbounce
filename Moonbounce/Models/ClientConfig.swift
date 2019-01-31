//
//  ReplicantClientConfig.swift
//  Moonbounce
//
//  Created by Adelita Schule on 1/14/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation
import Network

public class ClientConfig: NSObject, Codable, NSSecureCoding
{
    public static var supportsSecureCoding = true
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self, forKey: clientConfigKey)
    }

    public required init?(coder aDecoder: NSCoder)
    {
        if let obj = aDecoder.decodeObject(of:ClientConfig.self, forKey: clientConfigKey)
        {
            self.host = obj.host
            self.port = obj.port
        }
        else
        {
            return nil
        }
    }
    
    let clientConfigKey = "ClientConfig"
    public let host: NWEndpoint.Host
    public let port: NWEndpoint.Port
    
    public init(withPort port: NWEndpoint.Port, andHost host: NWEndpoint.Host)
    {
        self.port = port
        self.host = host
    }
    
    public init?(withConfigAtPath path: String)
    {
        guard let config = ClientConfig.parseJSON(atPath:path)
            else
        {
            return nil
        }
        
        self.port = config.port
        self.host = config.host
    }
    
    /// Creates and returns a JSON representation of the ServerConfig struct.
    public func createJSON() -> Data?
    {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do
        {
            let serverConfigData = try encoder.encode(self)
            return serverConfigData
        }
        catch (let error)
        {
            print("Failed to encode Server config into JSON format: \(error)")
            return nil
        }
    }
    
    /// Checks for a valid JSON at the provided path and attempts to decode it into a server configuration file. Returns a ServerConfig struct if it is successful
    /// - Parameters:
    ///     - path: The complete path where the config file is located.
    /// - Returns: The ReplicantServerConfig struct that was decoded from the JSON file located at the provided path, or nil if the file was invalid or missing.
    static public func parseJSON(atPath path: String) -> ClientConfig?
    {
        let filemanager = FileManager()
        let decoder = JSONDecoder()
        
        guard let jsonData = filemanager.contents(atPath: path)
            else
        {
            return nil
        }
        
        do
        {
            let config = try decoder.decode(ClientConfig.self, from: jsonData)
            return config
        }
        catch (let error)
        {
            print("\nUnable to decode JSON into ServerConfig: \(error)\n")
            return nil
        }
    }
}

//extension ClientConfig: Equatable
//{
//    public static func == (lhs: ClientConfig, rhs: ClientConfig) -> Bool
//    {
//        return lhs.host == rhs.host &&
//            lhs.port == rhs.port
//    }
//}

enum ClientConfigError: Error
{
    case invalidPort
}
