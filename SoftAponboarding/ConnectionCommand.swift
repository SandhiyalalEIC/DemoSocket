//
// ConnectionCommand.swift
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

private enum CommandRawName: String, Decodable {
    case claimStatus
    case getWiFiNetworks
    case getRegisterStatus
    case changeNetworkCredentials
    case getConnectivityStatus
    case setWiFiCredentials
}

/// https://acs.arlo.com/display/AFS/Arlo+Device+Onboarding+with+SoftAP
enum ConnectionCommand {
    case claimStatus
    case wiFiNetworks
    case registerStatus
    case changeNetworkCredentials
    case connectivityStatus
    case setWiFiCredentials(credentials: WiFiCredentials?)
    
    var executable: ExecutableCommand {
        switch self {
        case .setWiFiCredentials(let credentials):
            return ExecutableCommand(type: self, credentials: credentials)
        default:
            return ExecutableCommand(type: self)
        }
    }
    
    /// - note: Usually the enumeration in swift can be parsed using decodable automatically,
    /// in this case because one of the enumeration cases has an associated value this is no possible in current swift version
    /// keep in mind that this could change in future versions and rawName can be removed in that case because there are no other usages.
    var rawName: String {
        switch self {
        case .claimStatus:
            return CommandRawName.claimStatus.rawValue
        case .wiFiNetworks:
            return CommandRawName.getWiFiNetworks.rawValue
        case .registerStatus:
            return CommandRawName.getRegisterStatus.rawValue
        case .changeNetworkCredentials:
            return CommandRawName.changeNetworkCredentials.rawValue
        case .connectivityStatus:
            return CommandRawName.getConnectivityStatus.rawValue
        case .setWiFiCredentials:
            return CommandRawName.setWiFiCredentials.rawValue
        }
    }
}

extension ConnectionCommand: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawName)
    }
}

extension ConnectionCommand: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(CommandRawName.self)
        
        switch rawValue {
        case CommandRawName.claimStatus:
            self = .claimStatus
        case CommandRawName.getWiFiNetworks:
            self = .wiFiNetworks
        case CommandRawName.getRegisterStatus:
            self = .registerStatus
        case CommandRawName.changeNetworkCredentials:
            self = .changeNetworkCredentials
        case CommandRawName.getConnectivityStatus:
            self = .connectivityStatus
        case CommandRawName.setWiFiCredentials:
            self = .setWiFiCredentials(credentials: nil)
        }
    }
}

extension ConnectionCommand: Equatable {
    static func == (lhs: ConnectionCommand, rhs: ConnectionCommand) -> Bool {
        switch (lhs, rhs) {
        case (.claimStatus, .claimStatus):
          return true
        case (.wiFiNetworks, .wiFiNetworks):
          return true
        case (.registerStatus, .registerStatus):
          return true
        case (.changeNetworkCredentials, .changeNetworkCredentials):
          return true
        case (.connectivityStatus, .connectivityStatus):
          return true
        case (.setWiFiCredentials, .setWiFiCredentials):
          return true
        default:
            return false
        }
    }
}
