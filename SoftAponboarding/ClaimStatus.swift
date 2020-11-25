//
// ClaimStatus.swift
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

protocol SocketMessage: Codable { }

struct ClaimStatus: SocketMessage {
    let claimStatus: ClaimStatus
    let claimCode: String
    let wifiNetworks: [WiFiNetwork]
}

extension ClaimStatus {
    enum ClaimStatus: String, Codable {
        case claimed, unclaimed
    }
}
