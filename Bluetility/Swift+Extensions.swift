//
//  Swift+Extensions.swift
//  Bluetility
//
//  Created by Joseph Ross on 7/1/20.
//  Copyright © 2020 Joseph Ross. All rights reserved.
//

import Foundation

// MARK: Data

extension Data {
    var hexString: String {
        var hex:String = ""
        for byte in self {
            hex += String(format: "%02X", byte)
        }
        return hex
    }
}

// MARK: Dictionary

func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

