//
// WiFiNetworkswift
// Created on 9/13/20
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

struct WiFiNetworks: SocketMessage {
    private enum CodingKeys: String, CodingKey {
        case networks = "wifiNetworks"
    }
    let networks: [WiFiNetwork]
}

struct WiFiNetwork: SocketMessage {
    let ssid: String
    let encrypt: String
    let band: String
    let rssi: Int
}

struct WiFiCredentials: SocketMessage {
    var ssid: String
    var password: String
   
    init(ssid: String, password: String) {
        self.ssid = ssid
        self.password = password
    }
}

extension WiFiCredentials: EncryptableMessage {
    mutating func encrypt(using encryptor: Encryptor) throws {
        let rawSSID = try encryptor.encrypt(ssid).base64EncodedString()
        let rawPassword = try encryptor.encrypt(password).base64EncodedString()
        
        self.ssid = rawSSID
        self.password = rawPassword
    }
}
