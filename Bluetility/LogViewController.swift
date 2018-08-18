//
//  LogViewController.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/29/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa
import CoreBluetooth

class LogViewController: NSViewController {
    
    @IBOutlet var logText:NSTextView! = nil
    fileprivate var logEntries:[LogEntry] = []
    var savePanel:NSSavePanel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func appendRead(_ characteristic:CBCharacteristic) {
        appendCharacteristicOperation(characteristic, operationType: .Read)
    }
    
    func appendWrite(_ characteristic:CBCharacteristic) {
        appendCharacteristicOperation(characteristic, operationType: .Write)
    }
    
    fileprivate func appendCharacteristicOperation(_ characteristic:CBCharacteristic, operationType:OperationType) {
        let data = characteristic.value ?? Data()
        let hexString = hexStringForData(data)
        appendLogText("UUID \(characteristic.uuid.uuidString) \(operationType) Value: 0x\(hexString)")
        let logEntry = LogEntry(serviceUUID: characteristic.service.uuid.uuidString,
            charUUID: characteristic.uuid.uuidString,
            operation: operationType,
            data: hexString,
            timestamp: Date()
        )
        logEntries.append(logEntry)
    }
    
    func appendLogText(_ message:String) {
        logText.textStorage?.append(NSAttributedString(string:message + "\n"))
        logText.scrollToEndOfDocument(self)
    }
    
    @IBAction func clearLogPressed(_ sender:NSButton) {
        logText.string = ""
        logEntries = []
    }
    
    @IBAction func saveCSVPressed(_ sender:NSButton) {
        savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["csv"]
        //savePanel.nameFieldStringValue = "Save Logs as csv"
        savePanel.beginSheetModal(for: self.view.window!) { (result) -> Void in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.savePanel.orderOut(self)
                if let selectedUrl = self.savePanel.url {
                    var contents:String = "service,characteristic,operation,data,timestamp\n"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    for logEntry in self.logEntries {
                        let timeString = dateFormatter.string(from: logEntry.timestamp)
                        contents += "\(logEntry.serviceUUID),\(logEntry.charUUID),\(logEntry.operation),\(logEntry.data),\(timeString)\n"
                    }
                    do {
                        try contents.write(to: selectedUrl, atomically: true, encoding: String.Encoding.utf8)
                    } catch {
                        //TODO: Display error to user
                    }
                }
            }
        }
    }
    
}

private enum OperationType : String {
    case Read, Write
}

private struct LogEntry {
    let serviceUUID:String
    let charUUID:String
    let operation:OperationType
    let data:String
    let timestamp:Date
}
