//
// Encryptor.swift
// Created on 9/25/20
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

protocol Encryptor {
    func encrypt(_ text: String) throws -> Data
    func decrypt(_ data: Data) throws -> String?
}
