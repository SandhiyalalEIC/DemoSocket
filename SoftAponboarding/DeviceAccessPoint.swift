//
// DeviceAccessPoint.swift
// Created on 8/18/20
//
// Copyright (c) 2020, Arlo Technologies, Inc.
// All rights reserved.
//
//
// This software is the confidential and proprietary information of
// Arlo Technologies, Inc. ("Confidential Information"). You shall not
// disclose such Confidential Information and shall use it only in
// accordance with the terms of the license agreement you entered into
// with Arlo.
//
// @author Jorge Ferrini
//
// 

import Foundation

/// Access point information is usally retrieved encrypted from BE with a public key generated in OnboardingEncryptor.
/// this structure  provides enough flexibility to create encrypted and not encrypted access points.
/// - Warning: If you know the source of the access point information encrypts the data,
/// please be sure you decrypt it using the same OnboardingEncryptor object used for public key generation.
struct DeviceAccessPoint {
    
    private(set) var ssid: String // Encrypted
    private(set) var passphrase: String // Encrypted
    let isAPSupported: Bool
    let isBSSupported: Bool
    var uuid: String?
    
    private var isDataEncrypted: Bool = true
    
    mutating func decrypt(with encryptor: Encryptor) {
        guard isDataEncrypted else {
            return
        }

        do {
            self.ssid = try decrypt(ssid, with: encryptor) ?? ""
            self.passphrase = try decrypt(passphrase, with: encryptor) ?? ""
            isDataEncrypted = false
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func decrypt(_ value: String, with decryptor: Encryptor) throws -> String? {
        guard let data = Data(base64Encoded: value),
              let rawValue = try decryptor.decrypt(data) else {
            return nil
        }
        return rawValue
    }
}

extension DeviceAccessPoint: Decodable {
    private enum CodingKeys: String, CodingKey {
        case ssid       = "softAPSSID"
        case passphrase = "softAPPasswd"
        case isAPSupported
        case isBSSupported
    }
    
    init(ssid: String, passphrase: String) {
        self.ssid = ssid
        self.passphrase = passphrase
        isAPSupported = false
        isBSSupported = false
    }
}

extension DeviceAccessPoint: CustomDebugStringConvertible {
    var debugDescription: String {
        return ssid
    }
}

extension DeviceAccessPoint: CustomStringConvertible {
    /// - important: Do not use to print in logs.
    var description: String {
        guard let uuid = uuid else {
            return ssid + passphrase
        }
        return uuid + ssid + passphrase
    }
}
