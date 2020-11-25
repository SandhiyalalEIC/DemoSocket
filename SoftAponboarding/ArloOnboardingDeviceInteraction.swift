//
// ArloOnboardingDeviceInteraction.swift
// Created on 9/18/20
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
import RxCocoa

extension Observable where Element == SoftApSocketEvent {
    func monitorMessage(by type: ConnectionCommand) -> Single<Element> {
        return self.filter({ $0.type == type })
            .take(1)
            .asSingle()
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == SoftApSocketEvent {
    typealias SingleSocketEvent = SingleEvent<PrimitiveSequence<SingleTrait, SoftApSocketEvent>.Element>
    
    func bindCommandResult(into single: @escaping (SingleSocketEvent) -> Void) -> Disposable {
        return subscribe(onSuccess: { event in
            single(.success(event))
        }, onError: { error in
            single(.error(error))
        })
    }
}

typealias ArloDeviceInteractor = AccessPointConnector & DeviceConnectionInteraction

/// Arlo Onborading Device Interaction should be used to initialize a communication with a particular device via soft access point
class ArloOnboardingDeviceInteraction: AccessPointConnector {
    
    static private let defaultPort = 50000
    static private let defaultSocketHost = "192.168.1.1"

    /// SSID of the network that this class is trying or will try to connect to
    var networkName: String {
        return networkConnection.networkName
    }
    
    /// Subscribe to eventsStream to receive messages from the device once a command is executed.
    var eventsStream: Observable<SoftApSocketEvent> {
        return deviceConnection.eventsStream
    }
    
    /// Subscribe to connection status updates to get the latest information about connection status
    /// it could be used to route application to right views in case of errors.
    var status: BehaviorRelay<DeviceAccessPointConnector.Status> {
        return networkConnection.status
    }
    
    /// Subscribe to isStreamAvaiable to get the latest known socket connection status,
    /// it will filter return just connected as a single value sequence.
    var isStreamAvailable: Single<Bool> {
        return streamAvailability
            .filter { $0 == true }
            .take(1)
            .asSingle()
            .observeOn(MainScheduler.instance)
    }
    
    private var numberOfConnectionAttempts = 0
    private var networkConnectionStatus: Disposable?
    private var deviceConnectionStatus: Disposable? {
        willSet {
            registerReconnectionAttempt()
            deviceConnectionStatus?.dispose() // Dispose if exist
            streamAvailability.accept(false)
        }
    }

    private let streamAvailability = BehaviorRelay<Bool>.init(value: false)
    private let networkConnection: AccessPointConnector
    private let deviceConnection: DeviceConnectionInteraction
    private let disposeBag = DisposeBag()
    
    init(with accessPoint: DeviceAccessPoint) {
        let socket = SoftAPSocket(port: ArloOnboardingDeviceInteraction.defaultPort,
                                  host: ArloOnboardingDeviceInteraction.defaultSocketHost)
        
        self.networkConnection = DeviceAccessPointConnector(connectingTo: accessPoint)
        
        let encryptor = MessageEncryptor(initialKey: accessPoint.description)
        self.deviceConnection = ArloDeviceConnection(type: .socket(info: socket, encryptor: encryptor))
    }
    
    deinit {
        print("Deinit - disconnect and remove configuration from SSID list.")
        networkConnection.disconnect()
    }
    
    func join() {
        resetAttempts()
        networkConnection.join()
        setupNetworkMonitorSubscription()
    }
}

extension ArloOnboardingDeviceInteraction: DeviceConnectionInteraction {
    func connect() -> Observable<ArloDeviceConnection.StreamStatus>? {
        return deviceConnection.connect()
    }
        
    func disconnect() {
        networkConnection.disconnect()
        deviceConnection.disconnect()
        
        // Enforce dispose for possible reconnection
        networkConnectionStatus?.dispose()
        deviceConnectionStatus?.dispose()
        networkConnectionStatus = nil
        deviceConnectionStatus = nil
        
        streamAvailability.accept(false)
    }
    
    func execute(command: ConnectionCommand) {
        deviceConnection.execute(command: command)
    }

    func executeAndReturnResponse(command: ConnectionCommand) -> Single<SoftApSocketEvent> {
        return Single<SoftApSocketEvent>.create { [weak self] single in
            guard let sself = self else {
                single(.error(DeviceInteractionError.instanceDestroyed))
                return Disposables.create()
            }
            sself.isStreamAvailable
                .subscribe { _ in
                    sself.deviceConnection
                        .executeAndReturnResponse(command: command)
                        .bindCommandResult(into: single)
                        .disposed(by: sself.disposeBag)
                }.disposed(by: sself.disposeBag)
            return Disposables.create()
        }
    }
}

private extension ArloOnboardingDeviceInteraction {
    static let maxReconnectionAttempts = 3
    
    func setupNetworkMonitorSubscription() {
        networkConnectionStatus = networkConnection.status
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] status in
                if case .connected = status {
                    self?.setupDeviceInteraction()
                }
                print("connection status: \(status)")
            })
        networkConnectionStatus?.disposed(by: disposeBag)
    }
    
    func setupDeviceInteraction() {
        guard numberOfConnectionAttempts <= ArloOnboardingDeviceInteraction.maxReconnectionAttempts else {
            networkConnection.status.accept(.failedConnection)
            disconnect()
            deviceConnectionStatus?.dispose()
            return
        }

        print("Socket connection attempt: \(numberOfConnectionAttempts) disposing previous device connection status.")
        deviceConnectionStatus?.dispose()
        
        deviceConnectionStatus = connect()?
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] status in
                print("Socket monitoring \(status)")
                guard !(self?.isReconnectionNeeded(from: status) ?? false) else {
                    self?.setupDeviceInteraction()
                    return
                }
                self?.bindStreamAvailability(status)
            }, onError: {[weak self] error in
                print("Error: \(error.localizedDescription)")
                self?.setupDeviceInteraction()
            })
        deviceConnectionStatus?.disposed(by: disposeBag)
    }
    
    func isReconnectionNeeded(from status: ArloDeviceConnection.StreamStatus) -> Bool {
        guard status != .disconnected, status != .timeout else {
            print("Reconnection Needed for \(status)")
            return true
        }
        return false
    }
    
    func bindStreamAvailability(_ status: ArloDeviceConnection.StreamStatus) {
        guard status == .open else {
            streamAvailability.accept(false)
            print("Stream unavailable")
            return
        }
        streamAvailability.accept(true)
        print("Stream available")
    }
    
    func registerReconnectionAttempt() {
        numberOfConnectionAttempts += 1
    }
    
    func resetAttempts() {
        numberOfConnectionAttempts = 0
    }
}
