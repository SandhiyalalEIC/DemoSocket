//
// LocationPermissionMonitor.swift
// Created on 8/21/20
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
import CoreLocation

protocol LocationPermissionMonitor {
    @discardableResult func locationPermissionGranted() -> Bool
}

struct OnboardingLocationMonitor: LocationPermissionMonitor {
    
    func locationPermissionGranted() -> Bool {
        let status = CLLocationManager.authorizationStatus()
//        guard CLLocationManager.locationServicesEnabled(), status != .notDetermined else {
//            HMSGeofencing.instance().requestAuthorizationIfNeededWithoutFirstTimeCheck()
//            return false
//        }
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }
}
