//
// EncryptionKeyFactory.swift
// Created on 8/17/20
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

struct EncryptionKeyFactory {
    private enum EncryptionFactoryError: Error {
        case keyCreation
    }
    
    private static let size = 2048
    
    static func generateKey(for type: CFString) throws -> SecKey {
        var error: Unmanaged<CFError>?
        let attributes = EncryptionKeyFactory.commonAttributes(for: type, with: EncryptionKeyFactory.size)
        
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            if let error = error {
                throw error.takeRetainedValue() as Error
            }
            throw EncryptionFactoryError.keyCreation
        }
        return privateKey
    }
    
    private static func commonAttributes(for algorithmType: CFString, with size: Int) -> [String: Any] {
        return [
            kSecAttrKeyType as String: algorithmType,
            kSecAttrKeySizeInBits as String: size,
            kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String: false]
        ]
    }
}
