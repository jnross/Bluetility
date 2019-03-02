//
//  StringUtils.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/29/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

extension Data {
    var hexString: String {
        var hex:String = ""
        for byte in self {
            hex += String(format: "%02X", byte)
        }
        return hex
    }
}
