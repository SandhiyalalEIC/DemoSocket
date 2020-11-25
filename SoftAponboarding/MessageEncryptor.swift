//
// MessageEncryptor.swift
// Created on 10/14/20
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
import CryptoSwift

class MessageEncryptor {
    let plainKey: String // SHA256
    let initialVector: [UInt8]
    
    let paddingProtocol: Padding = .noPadding

    var key: [UInt8] {
        return plainKey.bytes.sha256()
    }
    
    init(initialKey: String) {
        let salt = ""
       // Log.debug("Got salt? \(salt.isEmpty)")
        
        self.plainKey = initialKey + salt
        self.initialVector = salt.bytes
    }
}

extension MessageEncryptor: Encryptor {
    func encrypt(_ text: String) throws -> Data {
        let gcm = GCM(iv: initialVector, mode: .combined)
        let aes = try AES(key: key, blockMode: gcm, padding: paddingProtocol)
        let encrypted = try aes.encrypt(text.bytes)

        return Data(encrypted)
    }
    
    func decrypt(_ data: Data) throws -> String? {
        let gcm = GCM(iv: initialVector, mode: .combined)
        let aes = try AES(key: key, blockMode: gcm, padding: paddingProtocol)
        let result = try aes.decrypt(data.bytes)
        return String(bytes: result, encoding: .utf8)
    }
}
