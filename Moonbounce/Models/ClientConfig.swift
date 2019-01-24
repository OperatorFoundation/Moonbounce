//
//  ReplicantClientConfig.swift
//  Moonbounce
//
//  Created by Adelita Schule on 1/14/19.
//  Copyright © 2019 operatorfoundation.org. All rights reserved.
//

import Foundation
import Network

public struct ClientConfig: Codable
{
    public let host: NWEndpoint.Host
    public let port: NWEndpoint.Port
    
    public init(withPort port: NWEndpoint.Port, andHost host: NWEndpoint.Host)
    {
        self.port = port
        self.host = host
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
            print("\nUnable to get JSON data at path: \(path)\n")
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

extension ClientConfig: Equatable
{
    public static func == (lhs: ClientConfig, rhs: ClientConfig) -> Bool
    {
        return lhs.host == rhs.host &&
            lhs.port == rhs.port
    }
}

//extension NWEndpoint.Port: Encodable
//{
//    public func encode(to encoder: Encoder) throws
//    {
//        let portInt = self.rawValue
//        var container = encoder.singleValueContainer()
//        
//        do
//        {
//            try container.encode(portInt)
//        }
//        catch let error
//        {
//            throw error
//        }
//    }
//}
//
//extension NWEndpoint.Port: Decodable
//{
//    public init(from decoder: Decoder) throws
//    {
//        do
//        {
//            let container = try decoder.singleValueContainer()
//            
//            do
//            {
//                let portInt = try container.decode(UInt16.self)
//                guard let port = NWEndpoint.Port(rawValue: portInt)
//                    else
//                {
//                    throw ClientConfigError.invalidPort
//                }
//                
//                self = port
//            }
//            catch let error
//            {
//                throw error
//            }
//        }
//        catch let error
//        {
//            throw error
//        }
//    }
//}

extension NWEndpoint.Host: Encodable
{
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        
        switch self
        {
        case .ipv4(let ipv4Address):
            do
            {
                let addressString = "\(ipv4Address)"
                try container.encode(addressString)
            }
            catch let error
            {
                throw error
            }
        case .ipv6(let ipv6Address):
            do
            {
                let addressString = "\(ipv6Address)"
                try container.encode(addressString)
            }
            catch let error
            {
                throw error
            }
        case .name(let nameString, _):
            do
            {
                try container.encode(nameString)
            }
            catch let error
            {
                throw error
            }
        }
    }
}

extension NWEndpoint.Host: Decodable
{
    public init(from decoder: Decoder) throws
    {
        do
        {
            let container = try decoder.singleValueContainer()
            
            do
            {
                let addressString = try container.decode(String.self)
                self.init(addressString)
            }
            catch let error
            {
                throw error
            }
        }
        catch let error
        {
            throw error
        }
    }
}

enum ClientConfigError: Error
{
    case invalidPort
}
