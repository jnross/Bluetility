//
//  StringUtils.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/29/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

func hexStringForData(data:NSData) -> String {
    var hex:String = ""
    var bytes:[UInt8] = []
    bytes = [UInt8](count:data.length, repeatedValue:0)
    data.getBytes(&bytes, length: data.length)
    for byte in bytes {
        hex += String(format: "%02X", arguments: [byte])
    }
    return hex
}