//
//  Scanner.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import CoreBluetooth;

class Scanner: NSObject {
    
    var central:CBCentralManager
    weak var delegate:CBCentralManagerDelegate?
    var devices:[Device] = []
    var started:Bool = false
    
    override init() {
        central = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        central.delegate = self
    }
    
    func start() {
        started = true
        devices = []
        startOpportunity()
    }
    
    func startOpportunity() {
        if central.state == .poweredOn && started {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
    }
    
    func stop() {
        started = false
        central.stopScan()
    }
    
    func restart() {
        stop()
        start()
    }
    
}

extension Scanner : CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        startOpportunity()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let existingDevice = devices.first(where: { $0.peripheral == peripheral } ) else {
            let newDevice = Device(peripheral: peripheral, advertisingData: advertisementData, rssi: RSSI.intValue)
            devices.append(newDevice)
            return
        }
        
        existingDevice.rssi = RSSI.intValue
        existingDevice.advertisingData += advertisementData
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.centralManager?(central, didConnect: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
    }
}

func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}


func log(_ message:String, file:String = #file, line:Int = #line, functionName:String = #function) {
    print("\(file):\(line) (\(functionName)): \(message)\n")
    
}
