//
// ExecutableCommand.swift
// Created on 9/11/20
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

struct ExecutableCommand {
    let type: ConnectionCommand
    private(set) var credentials: WiFiCredentials?
    
    init(type: ConnectionCommand, credentials: WiFiCredentials? = nil) {
        self.type = type
        self.credentials = credentials
    }
}

extension ExecutableCommand: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type = "opType"
        case data = "opData"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        if let credentialsData = credentials {
            try container.encode(credentialsData, forKey: .data)
        }
    }
}

extension ExecutableCommand: EncryptableMessage {
    mutating func encrypt(using encryptor: Encryptor) throws {
        try credentials?.encrypt(using: encryptor)
    }
}

extension ExecutableCommand: CustomStringConvertible {
    var description: String {
        guard let rawData = try? JSONEncoder().encode(self),
            let stringMsg = String(data: rawData, encoding: .utf8) else {
                print("Stream encoding error: can't encode this message")
                return ""
        }
        return stringMsg
    }
}
