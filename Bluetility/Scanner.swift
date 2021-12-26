//
//  Scanner.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import CoreBluetooth;

protocol ScannerDelegate: AnyObject {
    func scanner(_ scanner: Scanner, didUpdateDevices: [Device])
}

class Scanner: NSObject {
    
    var central:CBCentralManager
    weak var delegate:ScannerDelegate? = nil
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
        startIfReady()
    }
    
    private func startIfReady() {
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
        startIfReady()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let existingDevice = devices.first(where: { $0.peripheral == peripheral } ) else {
            let newDevice = Device(scanner: self, peripheral: peripheral, advertisingData: advertisementData, rssi: RSSI.intValue)
            devices.append(newDevice)
            return
        }
        
        existingDevice.rssi = RSSI.intValue
        existingDevice.advertisingData += advertisementData
        
        delegate?.scanner(self, didUpdateDevices: devices)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let device = devices.first(where:{ $0.peripheral == peripheral }) else { return }
        device.peripheralDidConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let device = devices.first(where:{ $0.peripheral == peripheral }) else { return }
        device.peripheralDidDisconnect(error: error)
    }
}



