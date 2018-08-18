//
//  StringUtils.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/29/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

func hexStringForData(_ data:Data) -> String {
    var hex:String = ""
    var bytes:[UInt8] = []
    bytes = [UInt8](repeating: 0, count: data.count)
    (data as NSData).getBytes(&bytes, length: data.count)
    for byte in bytes {
        hex += String(format: "%02X", arguments: [byte])
    }
    return hex
}
