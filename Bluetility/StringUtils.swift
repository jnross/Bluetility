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
    for byte in data {
        hex += String(format: "%02X", byte)
    }
    return hex
}
