//
// NetworkMonitor.swift
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

import RxCocoa
import SystemConfiguration.CaptiveNetwork

protocol NetworkMonitor {
    var status: BehaviorRelay<DefaultNetworkMonitor.NetworkStatus> { get }
    var locationMonitor: LocationPermissionMonitor { get }

    func start(for networkName: String?)
    func cancel()
}

extension NetworkMonitor {
    func connectedNetworkName() -> String? {
        guard locationMonitor.locationPermissionGranted() else {
            return nil
        }
        
        var ssid: String?
        if let interfaces: CFArray = CNCopySupportedInterfaces() {
            for i in 0 ..< CFArrayGetCount(interfaces) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if let data = unsafeInterfaceData as? [String: AnyObject] {
                    ssid = data["SSID"] as? String
                    break
                }
            }
        }
        return ssid
    }
}
