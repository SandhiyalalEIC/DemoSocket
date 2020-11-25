//
// ArloDeviceConnection.swift
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

struct ArloDeviceConnection: DeviceConnectionInteraction {

    /// Connection type are keys for idenfity the type of connection to the device you want to use.
    /// - important: To create new connection types please extend this enumeration and follow the DeviceConnectionInteraction protocol.
    enum ConnectionType {
        case socket(info: SoftAPSocket, encryptor: Encryptor)
    }
    
    /// Stream status are keys for socket input and output state representation
    enum StreamStatus {
        /// Uninitialized represents new socket connection is trying to be stablished:
        /// it means all streams are about to be created, and no operations could be performed until status is connected.
        case uninitialized
        
        /// Open represent connection status for connected streams:
        /// it means the stream is ready to be used either for write or read depending on stream type.
        case open
        
        /// Closed represent connection status for manually closed state:
        /// it means the socket connection was closed including also all open streams available.
        case closed
        
        /// Disconnected represent connection error after connection was established:
        /// it means the socket connection dropped either by NSStreamEventEndEncountered or NSStreamEventHasBytesAvailable with lenght = 0
        case disconnected
        
        /// Timeout represent connection status at first attemp to connect:
        /// it means the socket connection can't be establisehed in a period of time.
        /// please check the SocketInteraction configuration for more information about time out.
        case timeout
    }
    
    var eventsStream: Observable<SoftApSocketEvent>
    
    private let type: ConnectionType
    private let interactor: DeviceConnectionInteraction
    
    /**
     Initialize a new connection using an specific protocol type, for now just TCP socket are supported but is ready to be extended to add new protocols like Bluetooth.
     The connection itself will not start until you call the connec function, that will start the connection process, please make sure you subscribe to connect observable status.
     - Parameter type: the type of protocol you want to use to connect to the device.
     */
    init(type: ConnectionType) {
        self.type = type
        self.interactor = type.interactor
        self.eventsStream = interactor.eventsStream
    }
}

extension ArloDeviceConnection {
    /**
     Starts a connection process using specific protocol defined at initialization time.
     
     ~~~
     let deviceConnection = ArloDeviceConnection(type: .socket(info: socket))
     deviceConnection?.connect()?
         .subscribe(onNext: { status in
         // Process connection status.
     }, onError: { error in
         // Process observable error.
     }).disposed(by: disposeBag)
     ~~~
     
     - returns: Observable object with stream status.
     - important: Make sure you subscribe to the observable object to get real time connection status.
     */
    func connect() -> Observable<StreamStatus>? {
        return interactor.connect()
    }
    
    func disconnect() {
        interactor.disconnect()
    }
    
    func execute(command: ConnectionCommand) {
        interactor.execute(command: command)
    }
    
    func executeAndReturnResponse(command: ConnectionCommand) -> Single<SoftApSocketEvent> {
        interactor.executeAndReturnResponse(command: command)
    }
}

extension ArloDeviceConnection.ConnectionType {
    var interactor: DeviceConnectionInteraction {
        switch self {
        case .socket(let info, let encryptor):
            return SoftAPSocketInteraction(with: info, using: encryptor)
        }
    }
}
