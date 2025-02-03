//
//  Device.swift
//  Bluetility
//
//  Created by Joseph Ross on 7/1/20.
//  Copyright © 2020 Joseph Ross. All rights reserved.
//

import CoreBluetooth
import Logging

protocol DeviceDelegate: AnyObject {
    func deviceDidConnect(_ device: Device)
    func deviceDidDisconnect(_ device: Device)
    func deviceDidUpdateName(_ device: Device)
    func device(_ device: Device, updated services: [CBService])
    func device(_ device: Device, updated characteristics: [CBCharacteristic], for service: CBService)
    func device(_ device: Device, updatedValueFor characteristic: CBCharacteristic)
}

class Device : NSObject {
    let peripheral: CBPeripheral
    unowned var scanner: Scanner
    var advertisingData: [String:Any]
    var rssi: Int
    let logger = Logger(label: "com.rossible.Bluetility.Device")
    
    weak var delegate: DeviceDelegate? = nil
    
    // Transient data
    var manufacturerName: String? = nil
    var modelName: String? = nil
    var companyIdentifier: String? = nil
    
    init(scanner: Scanner, peripheral: CBPeripheral, advertisingData: [String: Any], rssi: Int) {
        self.scanner = scanner
        self.peripheral = peripheral
        self.advertisingData = advertisingData
        self.rssi = rssi
        
        super.init()
        
        extractCompanyIdentifier()
        peripheral.delegate = self
    }
    
    deinit {
        peripheral.delegate = nil
    }
    
    func extractCompanyIdentifier() {
        if let manufacturerData = self.advertisingData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 2 {
                let companyIdentifier = manufacturerData[0..<2].reversed().hexString
                self.companyIdentifier = COMPANY_IDENTIFIERS[companyIdentifier] ?? companyIdentifier
            }
        }
    }
    
    func updateAdvertisingData(_ newData:[String: Any]) {
        self.advertisingData += newData
        extractCompanyIdentifier()
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
    
    var services: [CBService] {
        return peripheral.services ?? []
    }
    
    func connect() {
        scanner.central.connect(self.peripheral, options: [:])
    }
    
    func disconnect() {
        scanner.central.cancelPeripheralConnection(self.peripheral)
    }
    
    func discoverCharacteristics(for service: CBService) {
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    func read(characteristic: CBCharacteristic) {
        peripheral.readValue(for: characteristic)
    }
    
    func write(data: Data, for characteristic: CBCharacteristic, type:CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
}

extension Device : CBPeripheralDelegate {
    func peripheralDidConnect() {
        peripheral.discoverServices(nil)
        delegate?.deviceDidConnect(self)
    }
    
    func peripheralDidDisconnect(error: Error?) {
        delegate?.deviceDidDisconnect(self)
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        delegate?.deviceDidUpdateName(self)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            // TODO: report an error?
            logger.error("Peripheral: \(peripheral.name ?? "-") didDiscoverServices encountered error: \(error)")
            return
        }
        let services = peripheral.services ?? []
        
        logger.info("Peripheral: \(peripheral.name ?? "-") didDiscoverServices: \(services.map({ $0.uuid }))")
        
        handleSpecialServices(services)
        
        delegate?.device(self, updated: services)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            // TODO: report an error?
            logger.error("Peripheral: \(peripheral.name ?? "-") didDiscoverCharacteristicsFor: \(service) encountered error: \(error)")
            return
        }
        let characteristics = service.characteristics ?? []
        
        logger.info("Peripheral: \(peripheral.name ?? "-") didDiscoverCharacteristics: \(characteristics.map({ $0.uuid })) for: \(service.uuid) ")
        handleSpecialCharacteristics(characteristics)
        
        delegate?.device(self, updated: characteristics, for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            // TODO: report an error?
            logger.error("Peripheral: \(peripheral.name ?? "-") didUpdateValueFor: \(characteristic) encountered error: \(error)")
            return
        }
        logger.info("Peripheral: \(peripheral.name ?? "-") didUpdateValueFor: \(characteristic.uuid) to: \(characteristic.value?.hexString ?? "nil")")
        
        handleSpecialCharacteristic(characteristic)
        delegate?.device(self, updatedValueFor: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            // TODO: report an error?
            logger.error("Peripheral: \(peripheral.name ?? "-") didWriteValueFor: \(characteristic) encountered error: \(error)")
        }
        // TODO: report successful write?
        logger.info("Peripheral: \(peripheral.name ?? "-") didWriteValueFor: \(characteristic) successfully")
    }
    
}

// MARK: Handle Special Characteristics

fileprivate let specialServiceUUIDs = [
    CBUUID(string: "180A"), // Device Information Service
]

fileprivate let manufacturerNameUUID = CBUUID(string: "2A29")
fileprivate let modelNumberUUID = CBUUID(string: "2A24")

fileprivate let specialCharacteristicUUIDs = [
    manufacturerNameUUID, // Manufacturer Name
    modelNumberUUID, // Model Number
]

extension Device {
    func handleSpecialServices(_ services: [CBService]) {
        for service in services {
            if specialServiceUUIDs.contains(service.uuid) {
                peripheral.discoverCharacteristics(specialCharacteristicUUIDs, for: service)
            }
        }
    }
    
    func handleSpecialCharacteristics(_ characteristics: [CBCharacteristic]) {
        for characteristic in characteristics {
            if specialCharacteristicUUIDs.contains(characteristic.uuid) {
                peripheral.readValue(for: characteristic)
                handleSpecialCharacteristic(characteristic)
            }
        }
    }
    
    func handleSpecialCharacteristic(_ characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }
        
        if specialCharacteristicUUIDs.contains(characteristic.uuid) {
            switch characteristic.uuid {
            case manufacturerNameUUID:
                manufacturerName = String(bytes: value, encoding: .utf8)
            case modelNumberUUID:
                modelName = String(bytes: value, encoding: .utf8)
            default:
                assertionFailure("Forgot to handle one of the UUIDs in specialCharacteristicUUIDs: \(characteristic.uuid)")
                logger.critical("Forgot to handle one of the UUIDs in specialCharacteristicUUIDs: \(characteristic.uuid)")
            }
            delegate?.deviceDidUpdateName(self)
        }
    }
}
