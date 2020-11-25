//
// WiFiNetworkMonitor.swift
// Created on 8/19/20
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

import RxCocoa

@available(iOS, deprecated:12.0, message:"Use WirelessNetworkMonitor instead")
class WiFiNetworkMonitor: NetworkMonitor {

    let status = BehaviorRelay<DefaultNetworkMonitor.NetworkStatus>.init(value: .unknown)
    let locationMonitor: LocationPermissionMonitor
    
    private static let checkInterval = 7.0

    private var timer: Timer?
    private var networkName: String?
    private var isWiFiReachable: Bool {
        return  true
    }

    init(with locationMonitor: LocationPermissionMonitor = OnboardingLocationMonitor()) {
        self.timer = nil
        self.locationMonitor = locationMonitor
        locationMonitor.locationPermissionGranted() // Check location permission
    }
    
    deinit {
        print("Monitoring stopped.")
        cancel()
    }
        
    func start(for networkName: String?) {
        self.networkName = networkName
        
        print("Monitoring started.")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: WiFiNetworkMonitor.checkInterval, repeats: true, block: { _ in
            self.processStatus()
        })
    }
    
    func cancel() {
        print("Monitoring canceled.")
        timer?.invalidate()
        timer = nil
    }
    
    func processStatus() {
        guard self.isWiFiReachable else {
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
        self.status.accept(self.networkName == self.connectedNetworkName() ? .connected : .disconnected)
    }
}
