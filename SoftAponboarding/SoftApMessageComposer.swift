//
// SoftApMessageComposer.swift
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

struct SoftApMessageComposer {
    private static let logTag = "SoftAPSocketConnection"
    private static let endCharacter = "\0"
    
    static func composeIncomingMessage(from buffer: UnsafeMutablePointer<UInt8>, lenght: Int) -> SoftApSocketEvent? {
        var rawMessage = String(bytesNoCopy: buffer,
                                length: lenght,
                                encoding: .utf8,
                                freeWhenDone: true)?
            .components(separatedBy: " ")
        
        rawMessage?.removeFirst()
        guard let message = rawMessage?.joined() else {
            print("Message does not contains any information")
            return nil
        }
        
        
        
        do {
            let rawJsonData = Data(message.replacingOccurrences(of: endCharacter, with: "").utf8)
            let softAPMessage = try JSONDecoder().decode(SoftApSocketEvent.self, from: rawJsonData)
            return softAPMessage
        } catch {
            print("Decoding error: \(error.localizedDescription)")
        }
        return nil
    }
}
