//
// OnboardingEncryptor.swift
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

extension String {
    func convertToCFData() -> CFData {
        let byteStr: [UInt8] = Array(self.utf8)
        return CFDataCreate(nil, byteStr, byteStr.count)
    }
}

extension SecKey: CustomStringConvertible {
    public var description: String {
        var error: Unmanaged<CFError>?
        guard let cfdata = SecKeyCopyExternalRepresentation(self, &error) else {
            print("Can't get key external representation.")
            return ""
        }
        return (cfdata as Data).base64EncodedString()
    }
}

struct OnboardingEncryptor {

    var publicKey: SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }
    
    private let privateKey: SecKey
    private let algorithmType: SecKeyAlgorithm = .rsaEncryptionPKCS1
    
    private enum EncryptionError: Error {
        case unsupportedAlgorithm
        case blockSizeExceeded
        case nonExistingKey
        case encrypt
        case decrypt
    }
    
    init() throws {
        self.privateKey = try EncryptionKeyFactory.generateKey(for: kSecAttrKeyTypeRSA)
    }
}

extension OnboardingEncryptor: Encryptor {
    func encrypt(_ text: String) throws -> Data {
        guard let publicKey = publicKey else {
            throw EncryptionError.nonExistingKey
        }
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithmType) else {
            throw EncryptionError.unsupportedAlgorithm
        }
        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(publicKey,
                                                         algorithmType,
                                                         text.convertToCFData(),
                                                         &error) as Data? else {
                                                            if let error = error {
                                                                throw error.takeRetainedValue() as Error
                                                            }
                                                            throw EncryptionError.encrypt
        }
        return cipherData
    }
    
    func decrypt(_ textData: Data) throws -> String? {
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithmType) else {
            throw EncryptionError.unsupportedAlgorithm
        }
        guard textData.count == SecKeyGetBlockSize(privateKey) else {
            throw EncryptionError.blockSizeExceeded
        }
        var error: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(privateKey,
                                                        algorithmType,
                                                        textData as CFData,
                                                        &error) as Data? else {
                                                            if let error = error {
                                                                throw error.takeRetainedValue() as Error
                                                            }
                                                            throw EncryptionError.decrypt
        }
        return String(data: clearText, encoding: .utf8)
    }
}
