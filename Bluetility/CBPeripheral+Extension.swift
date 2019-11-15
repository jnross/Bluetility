//
//  CBPeripheral+Extensions.swift
//  June Updater
//
//  Created by Chris DeSalvo on 9/11/19.
//  Copyright © 2019 June Life, Inc. All rights reserved.
//

import CoreBluetooth
import Foundation

#if os(macOS)
import IOBluetooth

extension IOBluetoothDevice {
    // NOTE: This is done because we've checked that this functions with macOS 10.14 through 10.15, but want a reminder that
    // this could fail in the future.
    @available(macOS, introduced: 10.13, deprecated: 10.16, message: "Check that its still valid.")
    static func from(peripheral: CBPeripheral) -> IOBluetoothDevice? {
        //NOTE: This will most likely break at some point.
        if let dict = NSDictionary(contentsOfFile: "/Library/Preferences/com.apple.bluetooth.plist") {
            if let devices = dict["CoreBluetoothCache"] as? NSDictionary {
                if let device = devices[peripheral.identifier.uuidString] as? NSDictionary {
                    if let address = device["DeviceAddress"] as? String {
                        return IOBluetoothDevice(addressString: address)
                    }
                }
            }
        }
        return nil
    }
}
#endif

extension CBPeripheral {
#if os(macOS)
    var isPaired: Bool {
        var paired = false
        
        if let device = IOBluetoothDevice.from(peripheral: self) {
            paired = device.isPaired()
        }
        return paired
    }
    
    var macAddr: String? {
        var addr: String?
        if let device = IOBluetoothDevice.from(peripheral: self) {
            addr = device.addressString.uppercased()
        }
        return addr
    }
#endif
    var logName: String {
        if let name = name {
            return "\(name) \(identifier.uuidString)"
        }
        
        return identifier.uuidString
    }
}
