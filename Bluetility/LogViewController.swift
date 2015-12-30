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
    private var logEntries:[LogEntry] = []
    var savePanel:NSSavePanel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func appendRead(characteristic:CBCharacteristic) {
        appendCharacteristicOperation(characteristic, operationType: .Read)
    }
    
    func appendWrite(characteristic:CBCharacteristic) {
        appendCharacteristicOperation(characteristic, operationType: .Write)
    }
    
    private func appendCharacteristicOperation(characteristic:CBCharacteristic, operationType:OperationType) {
        let data = characteristic.value ?? NSData()
        let hexString = hexStringForData(data)
        appendLogText("UUID \(characteristic.UUID.UUIDString) \(operationType) Value: 0x\(hexString)")
        let logEntry = LogEntry(serviceUUID: characteristic.service.UUID.UUIDString,
            charUUID: characteristic.UUID.UUIDString,
            operation: operationType,
            data: hexString,
            timestamp: NSDate()
        )
        logEntries.append(logEntry)
    }
    
    func appendLogText(message:String) {
        logText.textStorage?.appendAttributedString(NSAttributedString(string:message + "\n"))
        logText.scrollToEndOfDocument(self)
    }
    
    @IBAction func clearLogPressed(sender:NSButton) {
        logText.string = ""
        logEntries = []
    }
    
    @IBAction func saveCSVPressed(sender:NSButton) {
        savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["csv"]
        //savePanel.nameFieldStringValue = "Save Logs as csv"
        savePanel.beginSheetModalForWindow(self.view.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.savePanel.orderOut(self)
                if let selectedUrl = self.savePanel.URL {
                    var contents:String = "service,characteristic,operation,data,timestamp\n"
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    for logEntry in self.logEntries {
                        let timeString = dateFormatter.stringFromDate(logEntry.timestamp)
                        contents += "\(logEntry.serviceUUID),\(logEntry.charUUID),\(logEntry.operation),\(logEntry.data),\(timeString)\n"
                    }
                    do {
                        try contents.writeToURL(selectedUrl, atomically: true, encoding: NSUTF8StringEncoding)
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
    let timestamp:NSDate
}