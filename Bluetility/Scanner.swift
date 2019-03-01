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
    var devices:[CBPeripheral] = []
    var rssiForPeripheral:[CBPeripheral:NSNumber] = [:]
    var advDataForPeripheral:[CBPeripheral:[String:Any]] = [:]
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
        if devices.index(of: peripheral) == nil {
            devices.append(peripheral)
        }
        rssiForPeripheral[peripheral] = RSSI
        if advDataForPeripheral[peripheral] != nil {
            advDataForPeripheral[peripheral]! += advertisementData
        } else {
            advDataForPeripheral[peripheral] = advertisementData
        }
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
