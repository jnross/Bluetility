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

extension Array<UInt8> {
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

infix operator ??? : NilCoalescingPrecedence

func ??? (left: Any?, right: String) -> String {
    if let left = left {
        return String(describing: left)
    } else {
        return right
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
