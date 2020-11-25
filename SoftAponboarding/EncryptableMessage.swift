//
// EncryptableMessage.swift
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

typealias CryptoMessage = EncryptableMessage & DecrytableMessage

protocol EncryptableMessage {
    mutating func encrypt(using encryptor: Encryptor) throws
}

protocol DecrytableMessage {
    mutating func decrypt(message: String, with encryptor: Encryptor) throws -> String?
}
