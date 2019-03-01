//
//  ViewController.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController {
    
    let scanner = Scanner()
    var listUpdateTimer:Timer? = nil
    
    var connectedPeripheral:CBPeripheral? = nil
    var selectedService:CBService? = nil
    var selectedCharacteristic:CBCharacteristic? = nil
    var characteristicUpdatedDate:Date? = nil
    let dateFormatter = DateFormatter()
    
    @IBOutlet var browser:NSBrowser!
    @IBOutlet var writeAscii:NSTextField!
    @IBOutlet var writeHex:NSTextField!
    @IBOutlet var readButton:NSButton!
    @IBOutlet var subscribeButton:NSButton!
    
    var statusLabel:NSTextView = NSTextView()
    
    var logWindowController:NSWindowController? = nil
    var logViewController:LogViewController? = nil
    var tooltipTagForRow:[Int:NSView.ToolTipTag] = [:]
    var rowForTooltipTag:[NSView.ToolTipTag:Int] = [:]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scanner.delegate = self
        scanner.start()
        listUpdateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.listUpdateTimerFired), userInfo: nil, repeats: true)
        
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        browser.separatesColumns = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let refreshItem = self.view.window?.toolbar?.items[0]
        refreshItem?.action = #selector(ViewController.refreshPressed(_:))
        refreshItem?.target = self
        let sortItem = self.view.window?.toolbar?.items[1]
        sortItem?.action = #selector(ViewController.sortPressed(_:))
        let logItem = self.view.window?.toolbar?.items[2]
        logItem?.action = #selector(ViewController.logPressed(_:))
        if let statusItem = self.view.window?.toolbar?.items[4] {
            statusLabel.isEditable = false
            statusLabel.backgroundColor = NSColor.clear
            statusItem.view = statusLabel
            var size = statusItem.maxSize
            size.width = 150
            statusItem.maxSize = size
            statusLabel.frame = CGRect(x: 0,y: 0, width: size.width, height: size.height)
        }
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        setupCharacteristicControls()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject?) {
        if let peripheral = connectedPeripheral {
            scanner.central.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        selectedService = nil
        scanner.restart()
        resetTooltips()
    }
    
    @IBAction func sortPressed(_ sender: AnyObject?) {
        scanner.devices.sort { return scanner.rssiForPeripheral[$0]?.int32Value ?? 0 > scanner.rssiForPeripheral[$1]?.int32Value ?? 0 }
    }
    
    @IBAction func logPressed(_ sender: NSToolbarItem) {
        if let window = logWindowController?.window, window.isVisible || window.isMiniaturized {
            window.makeKeyAndOrderFront(self)
        } else {
            logWindowController?.window?.close()
            if let logWindowController = self.storyboard?.instantiateController(withIdentifier: "LogWindow") as? NSWindowController {
                logWindowController.shouldCascadeWindows = false
                logWindowController.window?.setFrameAutosaveName("bluetility_log")
                logWindowController.showWindow(sender)
                self.logWindowController = logWindowController
                self.logViewController = logWindowController.contentViewController as? LogViewController
            }
        }
    }
    
    @objc func listUpdateTimerFired() {
        browser.reloadColumn(0)
    }
    
    func resetTooltips() {
        browser.removeAllToolTips()
        rowForTooltipTag = [:]
        tooltipTagForRow = [:]
    }
}

extension ViewController : NSBrowserDelegate {
    func browser(_ sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
        switch column {
        case 0: return scanner.devices.count;
        case 1: return connectedPeripheral?.services?.count ?? 0
        case 2: return selectedService?.characteristics?.count ?? 0
        case 3: return 4
        default: return 0
        }
    }
    
    func browser(_ browser: NSBrowser, sizeToFitWidthOfColumn columnIndex: Int) -> CGFloat {
        return browser.width(ofColumn: columnIndex)
    }
    
    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        guard let cell = cell as? NSBrowserCell else { return }
        switch column {
        case 0:
            let peripheral = scanner.devices[row]
            cell.title = (peripheral.name ?? "Untitled") + "(\(scanner.rssiForPeripheral[peripheral] ?? 0))"
            let rect = browser.frame(ofRow: row, inColumn: column)
            if tooltipTagForRow[row] == nil {
                let tag = browser.addToolTip(rect, owner: self, userData: nil)
                tooltipTagForRow[row] = tag
                rowForTooltipTag[tag] = row
            }
        case 1:
            if let service = connectedPeripheral?.services?[row] {
                cell.title = titleForUUID(service.uuid)
            }
        case 2:
            if let characteristic = selectedService?.characteristics?[row] {
                cell.title = titleForUUID(characteristic.uuid)
            }
        case 3:
            setupCharacteristicDetailCell(cell, forRow:row)
        default:
            break
        }
    }
    
    func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String {
        if let row = rowForTooltipTag[tag] {
            let peripheral = scanner.devices[row]
            if let advData = scanner.advDataForPeripheral[peripheral] {
                return tooltipStringForAdvData(advData)
            }
            
        }
        return ""
    }
    
    func tooltipStringForAdvData(_ advData:[String:AnyObject]) -> String {
        var tooltip = ""
        if let mfgData = advData[CBAdvertisementDataManufacturerDataKey] as? Data {
            tooltip += "Mfg Data:\t\t0x\(hexStringForData(mfgData))\n"
            var bytes = [UInt8](repeating: 0, count: mfgData.count)
            (mfgData as NSData).getBytes(&bytes, length: mfgData.count)
            if bytes[0] == 0xd9 && bytes[1] == 0x01 {
                let uidBytes = [UInt8](bytes[6..<14])
                let uidData = Data(bytes: UnsafePointer<UInt8>(uidBytes), count: uidBytes.count)
                tooltip += "UID:\t\t\t\(hexStringForData(uidData))\n"
            }
        }
        if let localName = advData[CBAdvertisementDataLocalNameKey] as? String {
            tooltip += "Local Name:\t\(localName)\n"
        }
        var allServiceUUIDs:[CBUUID] = []
        if let serviceUUIDs = advData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            allServiceUUIDs += serviceUUIDs
        }
        if let serviceUUIDs = advData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] {
            allServiceUUIDs += serviceUUIDs
        }
        if allServiceUUIDs.count > 0 {
            tooltip += "Service UUIDs:\t\(allServiceUUIDs.map({return $0.uuidString}).joined(separator: ", "))\n"
        }
        if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            tooltip += "Tx Power:\t\t\(txPower)\n"
        }
        tooltip = tooltip.trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
        return tooltip
    }
    
    func titleForUUID(_ uuid:CBUUID) -> String {
        var title = uuid.description
        if (title.hasPrefix("Unknown")) {
            title = uuid.uuidString
        }
        return title
    }
    
    func browser(_ sender: NSBrowser, titleOfColumn column: Int) -> String? {
        switch column {
        case 0: return "Devices"
        case 1: return "Services"
        case 2: return "Characteristics"
        case 3: return "Detail"
        default: return ""
        }
    }
    
    func browser(_ browser: NSBrowser, shouldSizeColumn columnIndex: Int, forUserResize: Bool, toWidth suggestedWidth: CGFloat) -> CGFloat {
        if !forUserResize {
            if columnIndex == 0 {
                return 200
            }
        }
        return suggestedWidth
    }
    
    func selectPeripheral(_ peripheral:CBPeripheral) {
        if peripheral != connectedPeripheral {
            connectPeripheral(peripheral)
        }
    }
    
    func connectPeripheral (_ peripheral:CBPeripheral) {
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        scanner.central.connect(peripheral, options: [:])
        scanner.stop()
    }
    
    @IBAction
    func browserAction(_ sender:NSBrowser) {
        let indexPath = browser.selectionIndexPath
        let column = indexPath!.count
        browser.setTitle(self.browser(browser,titleOfColumn:column)!, ofColumn: column)
        // Automatically reconnect if a service or characteristic is selected.
        if [2,3].contains(column) {
            reconnectPeripheral()
        }
        if column == 1 {
            let peripheral = scanner.devices[(indexPath as! NSIndexPath).index(atPosition: 0)]
            if peripheral != connectedPeripheral {
                statusLabel.string = ""
            }
            selectPeripheral(peripheral)
            browser.reloadColumn(1)
        } else if column == 2 {
            if let service = connectedPeripheral?.services?[(indexPath as! NSIndexPath).index(atPosition: 1)] {
                selectedService = service
                connectedPeripheral?.discoverCharacteristics(nil, for: service)
                selectedCharacteristic = nil
                browser.reloadColumn(2)
            }
        } else if column == 3 {
            if let characteristic = selectedService?.characteristics?[(indexPath as! NSIndexPath).index(atPosition: 2)] {
                selectedCharacteristic = characteristic
                if characteristic.properties.contains(.read) {
                    readCharacteristic()
                    
                }
                refreshCharacteristicDetail()
            }
        }
        setupCharacteristicControls()
    }
    
    func reconnectPeripheral() {
        if let connectedPeripheral = connectedPeripheral, connectedPeripheral.state != .connected {
            scanner.central.connect(connectedPeripheral, options: [:])
        }
    }
    
    func setupCharacteristicControls() {
        let minimumWidth = CGFloat(150)
        let frameWidth = view.frame.size.width
        var otherWidth = browser.width(ofColumn: 0)
        otherWidth += browser.width(ofColumn: 1)
        otherWidth += browser.width(ofColumn: 2)
        
        let fitWidth = frameWidth - otherWidth - 6
        if fitWidth >= minimumWidth {
            browser.setWidth(fitWidth, ofColumn: 3)
            browser.scrollColumnToVisible(0)
        } else {
            browser.setWidth(minimumWidth, ofColumn: 3)
            browser.scrollColumnToVisible(0)
            browser.scrollColumnToVisible(3)
        }
        
        readButton.removeFromSuperview()
        subscribeButton.removeFromSuperview()
        writeAscii.removeFromSuperview()
        writeHex.removeFromSuperview()
        if let characteristic = selectedCharacteristic {
            let frame = browser.frame(ofColumn: 3)
            if characteristic.properties.contains(.read) {
                browser.addSubview(readButton)
                readButton.frame = CGRect(x: frame.origin.x + (frame.size.width/2 - 42),y: frame.origin.y + 120,width: 84,height: 32)
            }
            if !characteristic.properties.intersection([.write, .writeWithoutResponse]).isEmpty {
                browser.addSubview(writeAscii)
                browser.addSubview(writeHex)
                writeHex.frame = CGRect(x: frame.origin.x + (frame.size.width/2 - 75),y: frame.origin.y + 80,width: 150,height: 22)
                writeAscii.frame = CGRect(x: frame.origin.x + (frame.size.width/2 - 75),y: frame.origin.y + 40,width: 150,height: 22)
            }
            if !characteristic.properties.intersection([.indicate, .notify]).isEmpty {
                browser.addSubview(subscribeButton)
                subscribeButton.frame = CGRect(x: frame.origin.x + (frame.size.width/2 - 45),y: frame.origin.y + 150,width: 90,height: 32)
            }
        }
    }
    
    func refreshCharacteristicDetail() {
        browser.reloadColumn(3)
        
    }
    
    func setupCharacteristicDetailCell(_ cell:NSBrowserCell, forRow row:Int) {
        cell.isLeaf = true
        guard let characteristic = selectedCharacteristic else { return }
        switch row {
        case 0:
            if let ascii = String(data: characteristic.value ?? Data(), encoding: String.Encoding.ascii) {
                cell.title = "ASCII:\t" + ascii
            }
        case 1:
            var hex:String = ""
            if let value = characteristic.value {
                hex = hexStringForData(value)
            }
            cell.title = "Hex:\t\t" + hex
        case 2:
            if let value = characteristic.value, value.count <= 8 {
                var dec:Int64 = 0
                (value as NSData).getBytes(&dec, length: value.count)
                cell.title = "Decimal:\t\(dec)"
            }
        case 3:
            if let date = characteristicUpdatedDate {
                cell.title = "Updated:\t" + dateFormatter.string(from: date)
            }
        default:
            break
        }
    }
    
    func readCharacteristic() {
        if let characteristic = selectedCharacteristic, characteristic.properties.contains(.read) {
            connectedPeripheral?.readValue(for: characteristic)
        }
    }
    
    @IBAction
    func readButtonPressed(_ button:NSButton) {
        readCharacteristic()
    }
    
    @IBAction
    func subscribeButtonPressed(_ button:NSButton) {
        if let characteristic = selectedCharacteristic {
            connectedPeripheral?.setNotifyValue(true, for: characteristic)
        }
    }
    
    @IBAction
    func hexEntered(_ textField:NSTextField) {
        var bytes = [UInt8]()
        let text = textField.stringValue
        var i = text.startIndex
        while (i < text.endIndex) {
            //TODO: protect against badly formed strings
            let hexByte = text[i ... text.index(i, offsetBy: 2)]
            if let byte:UInt8 = UInt8(hexByte, radix:16) {
                bytes.append(byte)
            }
            i = text.index(i, offsetBy: 2)
        }
//        for var i = text.startIndex; i < text.endIndex; i = text.index(i, offsetBy: 2) {
//            
//        }
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        writeDataToSelectedCharacteristic(data)
        
    }
    
    @IBAction
    func asciiEntered(_ textField:NSTextField) {
        
        if let data = textField.stringValue.data(using: String.Encoding.ascii) {
            writeDataToSelectedCharacteristic(data)
        }
    }
    
    func writeDataToSelectedCharacteristic(_ data:Data) {
        log("writing data \(data)")
        if let characteristic = selectedCharacteristic {
                var writeType = CBCharacteristicWriteType.withResponse
                if (!characteristic.properties.contains(.write)) {
                    writeType = .withoutResponse
                }
                
                connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
        }
    }
    
    func appendLog(_ message:String) {
        logViewController?.logText.textStorage?.append(NSAttributedString(string:message + "\n"))
        logViewController?.logText.scrollToEndOfDocument(self)
    }
}

extension ViewController : IndexPathPasteboardDelegate {
    func pasteboardStringForIndexPath(_ indexPath: IndexPath) -> String? {
        if indexPath.count == 1 {
            let row = (indexPath as NSIndexPath).index(atPosition: 0)
            guard let tag = tooltipTagForRow[row], let peripheralName = scanner.devices[row].name else {return nil}
            return "Name:\t\t\t\(peripheralName)\n" + self.view(browser, stringForToolTip: tag, point: NSPoint(), userData: nil)
        }
        return nil
    }
}

extension ViewController : CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusLabel.string = (peripheral.name ?? "") + ":\n connected"
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let connectedPeripheral = connectedPeripheral {
            statusLabel.string = (connectedPeripheral.name ?? "") + ":\n disconnected"
        } else {
            statusLabel.string = ""
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}


extension ViewController : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        browser.reloadColumn(1)
        if browser.selectionIndexPath!.count == 2 {
            browserAction(browser)
        } else if let services = peripheral.services {
            for service in services {
                if service.uuid == selectedService?.uuid {
                    selectedService = service
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        browser.reloadColumn(2)
        if browser.selectionIndexPath!.count == 3 {
            browserAction(browser)
        } else if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == selectedCharacteristic?.uuid {
                    selectedCharacteristic = characteristic
                    if characteristic.properties.contains(.read) {
                        readCharacteristic()
                        
                    }
                    refreshCharacteristicDetail()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logViewController?.appendRead(characteristic)
        if characteristic == selectedCharacteristic {
            characteristicUpdatedDate = Date()
            refreshCharacteristicDetail()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logViewController?.appendWrite(characteristic)
    }
}
