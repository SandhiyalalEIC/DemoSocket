//
// DeviceAccessPointConnector.swift
// Created on 8/18/20
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
import NetworkExtension
import RxSwift
import RxCocoa

protocol AccessPointConnector {
    var networkName: String { get }
    var status: BehaviorRelay<DeviceAccessPointConnector.Status> { get }
    
    func join()
    func disconnect()
}

final class DeviceAccessPointConnector {
    
    enum Status: String {
        /// Starting represent the default state for a Access point connection, no operations should be performed in this state.
        case starting
        
        case connecting
        case connected
        
        /// Connection stoped manually by calling the disconnect function.
        case disconnected
        
        /// Connection Denied represents that NEHotSpot promt to join network was denied by final user.
        /// - important: At this step is developer responsability to take action to notify user that no connection could be done.
        case connectionDenied

        /// Failed connection represents bad credentials cases and connection drops.
        /// - important: Most likely failed connection because credentials case will never happens
        ///  the SSID and Password for device are retrieved from BE, if you see this in the logs please notify inmediately.
        case failedConnection
    }

    var networkName: String {
        return accessPoint.ssid
    }
    
    /// Sequence object with latest information about the connection status.
    private(set) var status = BehaviorRelay<Status>.init(value: .starting)
    
    private static let logTag = "SOFTAP"
    
    private let accessPoint: DeviceAccessPoint
    private let networkMonitor: NetworkMonitor?
    private let hotspotManager: HotspotConfigurationManager
    private let disposeBag = DisposeBag()

    init(connectingTo accessPoint: DeviceAccessPoint,
         withManager manager: HotspotConfigurationManager = NEHotspotConfigurationManager.shared) {
        
        manager.removeConfiguration(forSSID: accessPoint.ssid) // Remove in case of previous usage.
        
        self.accessPoint = accessPoint
        self.hotspotManager = manager

        if #available(iOS 12.0, *) {
            self.networkMonitor = WirelessNetworkMonitor()
        } else {
            self.networkMonitor = WiFiNetworkMonitor()
        }
    }
    
    deinit {
        networkMonitor?.cancel()
        disconnect()
    }
}

extension DeviceAccessPointConnector: AccessPointConnector {
    
    /// Connect will attempt to establish a connection to specific access point specified in the class initializer.
    /// same function could be used for reconnection
    func join() {
       // Log.debug("Connecting to ssid: \(String(reflecting: accessPoint))", tag: DeviceAccessPointConnector.logTag)
        print("Connecting to ssid: \(String(reflecting: accessPoint))")
        
        status.accept(.connecting)
        let configuration = NEHotspotConfiguration(ssid: accessPoint.ssid, passphrase: accessPoint.passphrase, isWEP: false)
        configuration.joinOnce = false
        
        hotspotManager.apply(configuration) { [weak self] error in
            guard let strongSelf = self else { return }
            guard error == nil else {
                print("Can't join network reason: \(error?.localizedDescription ?? "")")
                if let error = error as NSError?, error.code == NEHotspotConfigurationError.userDenied.rawValue {
                    strongSelf.status.accept(.connectionDenied)
                }
                strongSelf.status.accept(.failedConnection)
                return
            }
            
            if strongSelf.hotspotManager is MockHotspotConfigurationManager {
                strongSelf.status.accept(.connected)
                return
            }
            print("HostSpot manager report connected to SSID.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                strongSelf.bindNetworkMonitor()
                strongSelf.networkMonitor?.start(for: strongSelf.accessPoint.ssid)
            }
        }
    }
    
    func disconnect() {
        print("Disconnected from ssid: \(String(reflecting: accessPoint))")
        
        status.accept(.disconnected)
        networkMonitor?.cancel()
        hotspotManager.removeConfiguration(forSSID: accessPoint.ssid)
    }
}

private extension DeviceAccessPointConnector {
    static let debounceInterval: RxTimeInterval = .seconds(5)
    
    func bindNetworkMonitor() {
        networkMonitor?.status
            .skip(1)
            .debounce(DeviceAccessPointConnector.debounceInterval, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .disconnected:
                    self?.status.accept(.failedConnection)
                case .connected:
                    self?.status.accept(.connected)
                case .unknown:
                    print("Connection not determined yet.")
                }
                print("Connection to ssid result on status: \(status)")
            }).disposed(by: self.disposeBag)
    }
}

extension DeviceAccessPointConnector {
    /// - warning: Use it just for UT and to by pass WiFi connection if you try to connect to a local virtual machine that simulates your SoftAP Device
    struct MockHotspotConfigurationManager: HotspotConfigurationManager {
        func apply(_ configuration: NEHotspotConfiguration, completionHandler: ((Error?) -> Void)?) {
            completionHandler?(nil)
        }
        
        func removeConfiguration(forSSID SSID: String) { /* Conforms protocol */}
    }
}
