//
// SoftAPSocket.swift
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

struct SoftAPSocket {
    let port: Int
    let host: String
    
    init(port: Int, host: String) {
        self.port = port
        self.host = host
    }
}
