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
        if central.state == .PoweredOn && started {
            central.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
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
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        startOpportunity()
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let _ = devices.indexOf(peripheral) {} else {
            devices.append(peripheral)
            rssiForPeripheral[peripheral] = RSSI
        }
    
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        delegate?.centralManager?(central, didConnectPeripheral: peripheral)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
    }
}


func log(message:String, file:String = __FILE__, line:Int = __LINE__, functionName:String = __FUNCTION__) {
    print("\(file):\(line) (\(functionName)): \(message)\n")
    
}