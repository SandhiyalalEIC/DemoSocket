//
// SoftApSocketEvent.swift
// Created on 9/2/20
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

struct SoftApSocketEvent {
    enum Status: String, Codable {
        case success = "SUCCESS"
        case error   = "ERROR"
        case unknown
    }
    
    let type: ConnectionCommand
    let status: Status
    let data: SocketMessage?
}

extension SoftApSocketEvent: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type   = "opType"
        case status = "opStatus"
        case data   = "opData"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ConnectionCommand.self, forKey: .type)
        status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .error

        guard status == .success else {
            data = try container.decodeIfPresent(ErrorMessage.self, forKey: .data) ?? ErrorMessage(message: "Error decoding data")
            return
        }
        switch type {
        case .claimStatus:
            data = try container.decode(ClaimStatus.self, forKey: .data)
        case .wiFiNetworks, .changeNetworkCredentials:
            data = try container.decode(WiFiNetworks.self, forKey: .data)
        case .registerStatus:
            data = try container.decode(RegisterStatus.self, forKey: .data)
        case .connectivityStatus:
            data = try container.decode(ConnectivityStatus.self, forKey: .data)
        default:
            // setWifiCredentials doesn't need data just type and status.
            data = nil
        }
    }
}

extension SoftApSocketEvent: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        
        if case .claimStatus = type, let data = data as? ClaimStatus {
            try container.encode(data, forKey: .data)
        }
    }
}
