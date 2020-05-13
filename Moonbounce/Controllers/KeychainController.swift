//
//  KeychainController.swift
//  Moonbounce
//
//  Created by Adelita Schule on 4/14/17.
//  Copyright © 2017 operatorfoundation.org. All rights reserved.
//

import Foundation
import Security

//Identifiers
let userAccount = "DigitalOceanUser"
let accessGroup = "org.OperatorFoundation.Moonbounce"
let digitalOceanTokenKey = "DigitalOceanTokenKey"

let kSecClassValue = String(kSecClass)
let kSecAttrAccountValue = String(kSecAttrAccount)
let kSecValueDataValue = String(kSecValueData)
let kSecClassGenericPasswordValue = String(kSecClassGenericPassword)
let kSecAttrServiceValue = String(kSecAttrService)
let kSecMatchLimitValue = String(kSecMatchLimit)
let kSecReturnDataValue = String(kSecReturnData)
let kSecMatchLimitOneValue = String(kSecMatchLimitOne)

public class KeychainController: NSObject
{
    public class func saveToken(token: String)
    {
        self.save(service: digitalOceanTokenKey, data: token)
    }
    
    public class func loadToken() -> String?
    {
        return load(service: digitalOceanTokenKey)
    }
    
    private class func save(service: String, data: String)
    {
        guard let dataFromString = data.data(using: String.Encoding.utf8, allowLossyConversion: false)
        else
        {
            print("Unable to save data to keychain: string to data conversion failed.")
            return
        }
        
        //New Keychain Query
        let keychainQueryDictionary = [kSecClassValue: kSecClassGenericPasswordValue,
                                       kSecAttrServiceValue: service,
                                       kSecAttrAccountValue: userAccount,
                                       kSecValueDataValue: dataFromString] as CFDictionary
        
        //Delete any exisitng item.
        SecItemDelete(keychainQueryDictionary)
        
        //Add the new one.
        SecItemAdd(keychainQueryDictionary, nil)
    }
    
    private class func load(service: String) -> String?
    {
        //This query returns a result and return values are limited to one.
        let keychainQueryDictionary = [kSecClassValue: kSecClassGenericPasswordValue,
                                       kSecAttrServiceValue: service,
                                       kSecAttrAccountValue: userAccount,
                                       kSecReturnDataValue: kCFBooleanTrue as Any,
                                       kSecMatchLimitValue: kSecMatchLimitOneValue] as CFDictionary
        
        var dataTypeRef: AnyObject?
        
        //Search
        let status: OSStatus = SecItemCopyMatching(keychainQueryDictionary, &dataTypeRef)
        var contentsOfKeychain: String? = nil
        
        if status == errSecSuccess
        {
            if let retreivedData = dataTypeRef as? Data
            {
                contentsOfKeychain = String(data: retreivedData, encoding: String.Encoding.utf8)
            }
            else
            {
                print("No token was found in the keychain.")
            }
        }
        
        return contentsOfKeychain
    }

}
