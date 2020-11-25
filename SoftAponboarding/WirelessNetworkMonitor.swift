//
// WirelessNetworkMonitor.swift
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

import Network
import RxSwift
import RxCocoa

@available(iOS 12.0, *)
class WirelessNetworkMonitor: NetworkMonitor {

    let status = BehaviorRelay<DefaultNetworkMonitor.NetworkStatus>.init(value: .unknown)
    let locationMonitor: LocationPermissionMonitor

    private var networkName: String? // Not providing network name will just monitor WiFi connection.
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private let disposeBag = DisposeBag()
    
    private static let interfaceType = NWInterface.InterfaceType.wifi
    
    init(with locationMonitor: LocationPermissionMonitor = OnboardingLocationMonitor()) {
        self.locationMonitor = locationMonitor
        locationMonitor.locationPermissionGranted() // Check location permission
        
//        NotificationCenter.default.rx
//            .notification(Notification.Name(HMSNotificationGeofencingEnabledChanged))
//            .subscribe(onNext: { _ in
//                if self.locationMonitor.locationPermissionGranted() {
//                    self.monitor?.cancel()
//                    self.start(for: self.networkName)
//                }
//            }).disposed(by: disposeBag)
    }
    
    func start(for networkName: String?) {
        self.networkName = networkName
        
        monitor?.cancel() // If previous monitor exist because location permission
        print("Monitoring started for network \(networkName ?? "No network name").")
        
        monitor = NWPathMonitor(requiredInterfaceType: WirelessNetworkMonitor.interfaceType)
        registerHandler()
        monitor?.start(queue: monitorQueue)
    }
    
    func cancel() {
        print("Monitoring canceled.")
        monitor?.cancel()
    }
    
    func processStatus(_ status: NWPath.Status) {
        guard status == .satisfied else {
            print("Disconnected from WiFi.")
            self.status.accept(.disconnected)
            return
        }
        guard self.networkName != nil else {
            self.status.accept(.connected)
            print("Connected to WiFi no network name monitoring required.")
            return
        }
        guard locationMonitor.locationPermissionGranted() else {
            print("Location permissions not granted can't perform verification")
            return
        }
        let newStatus: DefaultNetworkMonitor.NetworkStatus = self.networkName == self.connectedNetworkName() ? .connected : .disconnected
        print("""
                Status \(newStatus)
                for networkName: \(networkName ?? "No network name")
                vs connectedNetworkName: \(connectedNetworkName() ?? "No network name")
        """)
        self.status.accept(newStatus)
    }
}
 
@available(iOS 12.0, *)
private extension WirelessNetworkMonitor {
    func registerHandler() {
        monitor?.pathUpdateHandler = { path in
            self.processStatus(path.status)
        }
    }
}
