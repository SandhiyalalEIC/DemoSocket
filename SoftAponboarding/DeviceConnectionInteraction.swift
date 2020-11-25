//
// DeviceConnectionInteraction.swift
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
import RxSwift

enum DeviceInteractionError: Error {
    case instanceDestroyed
    case notOpenConnection
}

protocol DeviceConnectionInteraction: DeviceInteractionExecutor {
    var eventsStream: Observable<SoftApSocketEvent> { get }

    func connect() -> Observable<ArloDeviceConnection.StreamStatus>?
    func disconnect()
}

protocol DeviceInteractionExecutor {
    func execute(command: ConnectionCommand)
    func executeAndReturnResponse(command: ConnectionCommand) -> Single<SoftApSocketEvent>
}
