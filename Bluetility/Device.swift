//
//  Device.swift
//  Bluetility
//
//  Created by Joseph Ross on 7/1/20.
//  Copyright © 2020 Joseph Ross. All rights reserved.
//

import CoreBluetooth

class Device {
    let peripheral: CBPeripheral
    var advertisingData: [String:Any]
    var rssi: Int
    
    // Transient data
    var manufacturerName: String? = nil
    var modelName: String? = nil
    
    init(peripheral: CBPeripheral, advertisingData: [String: Any], rssi: Int) {
        self.peripheral = peripheral
        self.advertisingData = advertisingData
        self.rssi = rssi
    }
    
    var friendlyName : String {
        if let advertisedName = advertisingData[CBAdvertisementDataLocalNameKey] as? String {
            return advertisedName
        }
        if let peripheralName = peripheral.name {
            return peripheralName
        }
        let infoFields = [manufacturerName, modelName].compactMap({$0})
        if infoFields.count > 0 {
            return infoFields.joined(separator: " ")
        }
        
        return "Untitled"
    }
    
    
}
