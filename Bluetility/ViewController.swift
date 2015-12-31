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
    var listUpdateTimer:NSTimer? = nil
    
    var connectedPeripheral:CBPeripheral? = nil
    var selectedService:CBService? = nil
    var selectedCharacteristic:CBCharacteristic? = nil
    var characteristicUpdatedDate:NSDate? = nil
    let dateFormatter = NSDateFormatter()
    
    @IBOutlet var browser:NSBrowser!
    @IBOutlet var writeAscii:NSTextField!
    @IBOutlet var writeHex:NSTextField!
    @IBOutlet var readButton:NSButton!
    @IBOutlet var subscribeButton:NSButton!
    
    var statusLabel:NSTextView = NSTextView()
    
    var logWindowController:NSWindowController? = nil
    var logViewController:LogViewController? = nil
    var tooltipTagForRow:[Int:NSToolTipTag] = [:]
    var rowForTooltipTag:[NSToolTipTag:Int] = [:]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scanner.delegate = self
        scanner.start()
        listUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("listUpdateTimerFired"), userInfo: nil, repeats: true)
        
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        browser.separatesColumns = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let refreshItem = self.view.window?.toolbar?.items[0]
        refreshItem?.action = Selector("refreshPressed:")
        refreshItem?.target = self
        let sortItem = self.view.window?.toolbar?.items[1]
        sortItem?.action = Selector("sortPressed:")
        let logItem = self.view.window?.toolbar?.items[2]
        logItem?.action = Selector("logPressed:")
        if let statusItem = self.view.window?.toolbar?.items[4] {
            statusLabel.editable = false
            statusLabel.backgroundColor = NSColor.clearColor()
            statusItem.view = statusLabel
            var size = statusItem.maxSize
            size.width = 150
            statusItem.maxSize = size
            statusLabel.frame = CGRectMake(0,0, size.width, size.height)
        }
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        setupCharacteristicControls()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func refreshPressed(sender: AnyObject?) {
        if let peripheral = connectedPeripheral {
            scanner.central.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        selectedService = nil
        scanner.restart()
        resetTooltips()
    }
    
    @IBAction func sortPressed(sender: AnyObject?) {
        scanner.devices.sortInPlace { return scanner.rssiForPeripheral[$0]?.intValue ?? 0 > scanner.rssiForPeripheral[$1]?.intValue ?? 0 }
    }
    
    @IBAction func logPressed(sender: NSToolbarItem) {
        if let window = logWindowController?.window where window.visible || window.miniaturized {
            window.makeKeyAndOrderFront(self)
        } else {
            logWindowController?.window?.close()
            if let logWindowController = self.storyboard?.instantiateControllerWithIdentifier("LogWindow") as? NSWindowController {
                logWindowController.shouldCascadeWindows = false
                logWindowController.window?.setFrameAutosaveName("bluetility_log")
                logWindowController.showWindow(sender)
                self.logWindowController = logWindowController
                self.logViewController = logWindowController.contentViewController as? LogViewController
            }
        }
    }
    
    func listUpdateTimerFired() {
        browser.reloadColumn(0)
    }
    
    func resetTooltips() {
        browser.removeAllToolTips()
        rowForTooltipTag = [:]
        tooltipTagForRow = [:]
    }
}

extension ViewController : NSBrowserDelegate {
    func browser(sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
        switch column {
        case 0: return scanner.devices.count;
        case 1: return connectedPeripheral?.services?.count ?? 0
        case 2: return selectedService?.characteristics?.count ?? 0
        case 3: return 4
        default: return 0
        }
    }
    
    func browser(browser: NSBrowser, sizeToFitWidthOfColumn columnIndex: Int) -> CGFloat {
        return browser.widthOfColumn(columnIndex)
    }
    
    func browser(sender: NSBrowser, willDisplayCell cell: AnyObject, atRow row: Int, column: Int) {
        guard let cell = cell as? NSBrowserCell else { return }
        switch column {
        case 0:
            let peripheral = scanner.devices[row]
            cell.title = (peripheral.name ?? "Untitled") + "(\(scanner.rssiForPeripheral[peripheral] ?? 0))"
            let rect = browser.frameOfRow(row, inColumn: column)
            if tooltipTagForRow[row] == nil {
                let tag = browser.addToolTipRect(rect, owner: self, userData: nil)
                tooltipTagForRow[row] = tag
                rowForTooltipTag[tag] = row
            }
        case 1:
            if let service = connectedPeripheral?.services?[row] {
                cell.title = titleForUUID(service.UUID)
            }
        case 2:
            if let characteristic = selectedService?.characteristics?[row] {
                cell.title = titleForUUID(characteristic.UUID)
            }
        case 3:
            setupCharacteristicDetailCell(cell, forRow:row)
        default:
            break
        }
    }
    
    override func view(view: NSView, stringForToolTip tag: NSToolTipTag, point: NSPoint, userData data: UnsafeMutablePointer<Void>) -> String {
        if let row = rowForTooltipTag[tag] {
            let peripheral = scanner.devices[row]
            if let advData = scanner.advDataForPeripheral[peripheral] {
                return tooltipStringForAdvData(advData)
            }
            
        }
        return ""
    }
    
    func tooltipStringForAdvData(advData:[String:AnyObject]) -> String {
        var tooltip = ""
        if let mfgData = advData[CBAdvertisementDataManufacturerDataKey] as? NSData {
            tooltip += "Mfg Data:\t\t0x\(hexStringForData(mfgData))\n"
            var bytes = [UInt8](count: mfgData.length, repeatedValue: 0)
            mfgData.getBytes(&bytes, length: mfgData.length)
            if bytes[0] == 0xd9 && bytes[1] == 0x01 {
                let uidBytes = [UInt8](bytes[6..<14])
                let uidData = NSData(bytes: uidBytes, length: uidBytes.count)
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
            tooltip += "Service UUIDs:\t\(allServiceUUIDs.map({return $0.UUIDString}).joinWithSeparator(", "))\n"
        }
        if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            tooltip += "Tx Power:\t\t\(txPower)\n"
        }
        tooltip = tooltip.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\n"))
        return tooltip
    }
    
    func titleForUUID(uuid:CBUUID) -> String {
        var title = uuid.description
        if (title.hasPrefix("Unknown")) {
            title = uuid.UUIDString
        }
        return title
    }
    
    func browser(sender: NSBrowser, titleOfColumn column: Int) -> String? {
        switch column {
        case 0: return "Devices"
        case 1: return "Services"
        case 2: return "Characteristics"
        case 3: return "Detail"
        default: return ""
        }
    }
    
    func browser(browser: NSBrowser, shouldSizeColumn columnIndex: Int, forUserResize: Bool, toWidth suggestedWidth: CGFloat) -> CGFloat {
        if !forUserResize {
            if columnIndex == 0 {
                return 200
            }
        }
        return suggestedWidth
    }
    
    func selectPeripheral(peripheral:CBPeripheral) {
        if peripheral != connectedPeripheral {
            connectPeripheral(peripheral)
        }
    }
    
    func connectPeripheral (peripheral:CBPeripheral) {
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        scanner.central.connectPeripheral(peripheral, options: [:])
        scanner.stop()
    }
    
    @IBAction
    func browserAction(sender:NSBrowser) {
        let indexPath = browser.selectionIndexPath
        let column = indexPath.length
        browser.setTitle(self.browser(browser,titleOfColumn:column)!, ofColumn: column)
        // Automatically reconnect if a service or characteristic is selected.
        if [2,3].contains(indexPath.length) {
            reconnectPeripheral()
        }
        if indexPath.length == 1 {
            let peripheral = scanner.devices[indexPath.indexAtPosition(0)]
            if peripheral != connectedPeripheral {
                statusLabel.string = ""
            }
            selectPeripheral(peripheral)
            browser.reloadColumn(1)
        } else if indexPath.length == 2 {
            if let service = connectedPeripheral?.services?[indexPath.indexAtPosition(1)] {
                selectedService = service
                connectedPeripheral?.discoverCharacteristics(nil, forService: service)
                selectedCharacteristic = nil
                browser.reloadColumn(2)
            }
        } else if indexPath.length == 3 {
            if let characteristic = selectedService?.characteristics?[indexPath.indexAtPosition(2)] {
                selectedCharacteristic = characteristic
                if characteristic.properties.contains(.Read) {
                    readCharacteristic()
                    
                }
                refreshCharacteristicDetail()
            }
        }
        setupCharacteristicControls()
    }
    
    func reconnectPeripheral() {
        if let connectedPeripheral = connectedPeripheral where connectedPeripheral.state != .Connected {
            scanner.central.connectPeripheral(connectedPeripheral, options: [:])
        }
    }
    
    func setupCharacteristicControls() {
        
        let frameWidth = view.frame.size.width
        var otherWidth = browser.widthOfColumn(0)
        otherWidth += browser.widthOfColumn(1)
        otherWidth += browser.widthOfColumn(2)
        
        let fitWidth = max(frameWidth - otherWidth - 6, 100)
        browser.setWidth(fitWidth, ofColumn: 3)
        
        readButton.removeFromSuperview()
        subscribeButton.removeFromSuperview()
        writeAscii.removeFromSuperview()
        writeHex.removeFromSuperview()
        if let characteristic = selectedCharacteristic {
            let frame = browser.frameOfColumn(3)
            if characteristic.properties.contains(.Read) {
                browser.addSubview(readButton)
                readButton.frame = CGRectMake(frame.origin.x + (frame.size.width/2 - 42),frame.origin.y + 120,84,32)
            }
            if !characteristic.properties.intersect([.Write, .WriteWithoutResponse]).isEmpty {
                browser.addSubview(writeAscii)
                browser.addSubview(writeHex)
                writeHex.frame = CGRectMake(frame.origin.x + (frame.size.width/2 - 75),frame.origin.y + 80,150,22)
                writeAscii.frame = CGRectMake(frame.origin.x + (frame.size.width/2 - 75),frame.origin.y + 40,150,22)
            }
            if !characteristic.properties.intersect([.Indicate, .Notify]).isEmpty {
                browser.addSubview(subscribeButton)
                subscribeButton.frame = CGRectMake(frame.origin.x + (frame.size.width/2 - 45),frame.origin.y + 150,90,32)
            }
        }
    }
    
    func refreshCharacteristicDetail() {
        browser.reloadColumn(3)
        
    }
    
    func setupCharacteristicDetailCell(cell:NSBrowserCell, forRow row:Int) {
        cell.leaf = true
        guard let characteristic = selectedCharacteristic else { return }
        switch row {
        case 0:
            if let ascii = String(data: characteristic.value ?? NSData(), encoding: NSASCIIStringEncoding) {
                cell.title = "ASCII:\t" + ascii
            }
        case 1:
            var hex:String = ""
            if let value = characteristic.value {
                hex = hexStringForData(value)
            }
            cell.title = "Hex:\t\t" + hex
        case 2:
            if let value = characteristic.value where value.length <= 8 {
                var dec:Int64 = 0
                value.getBytes(&dec, length: value.length)
                cell.title = "Decimal:\t\(dec)"
            }
        case 3:
            if let date = characteristicUpdatedDate {
                cell.title = "Updated:\t" + dateFormatter.stringFromDate(date)
            }
        default:
            break
        }
    }
    
    func readCharacteristic() {
        if let characteristic = selectedCharacteristic where characteristic.properties.contains(.Read) {
            connectedPeripheral?.readValueForCharacteristic(characteristic)
        }
    }
    
    @IBAction
    func readButtonPressed(button:NSButton) {
        readCharacteristic()
    }
    
    @IBAction
    func subscribeButtonPressed(button:NSButton) {
        if let characteristic = selectedCharacteristic {
            connectedPeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
        }
    }
    
    @IBAction
    func hexEntered(textField:NSTextField) {
        var bytes = [UInt8]()
        let text = textField.stringValue
        for var i = text.startIndex; i < text.endIndex; i = i.advancedBy(2) {
            //TODO: protect against badly formed strings
            let hexByte = text.substringWithRange(Range<String.Index>(start: i, end: i.advancedBy(2)))
            if let byte:UInt8 = UInt8(hexByte, radix:16) {
                bytes.append(byte)
            }
        }
        let data = NSData(bytes: bytes, length: bytes.count)
        writeDataToSelectedCharacteristic(data)
        
    }
    
    @IBAction
    func asciiEntered(textField:NSTextField) {
        
        if let data = textField.stringValue.dataUsingEncoding(NSASCIIStringEncoding) {
            writeDataToSelectedCharacteristic(data)
        }
    }
    
    func writeDataToSelectedCharacteristic(data:NSData) {
        log("writing data \(data)")
        if let characteristic = selectedCharacteristic {
                var writeType = CBCharacteristicWriteType.WithResponse
                if (!characteristic.properties.contains(.Write)) {
                    writeType = .WithoutResponse
                }
                
                connectedPeripheral?.writeValue(data, forCharacteristic: characteristic, type: writeType)
        }
    }
    
    func appendLog(message:String) {
        logViewController?.logText.textStorage?.appendAttributedString(NSAttributedString(string:message + "\n"))
        logViewController?.logText.scrollToEndOfDocument(self)
    }
}

extension ViewController : IndexPathPasteboardDelegate {
    func pasteboardStringForIndexPath(indexPath: NSIndexPath) -> String? {
        if indexPath.length == 1 {
            let row = indexPath.indexAtPosition(0)
            guard let tag = tooltipTagForRow[row], peripheralName = scanner.devices[row].name else {return nil}
            return "Name:\t\t\t\(peripheralName)\n" + self.view(browser, stringForToolTip: tag, point: NSPoint(), userData: nil)
        }
        return nil
    }
}

extension ViewController : CBCentralManagerDelegate {
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        statusLabel.string = (peripheral.name ?? "") + ":\n connected"
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let connectedPeripheral = connectedPeripheral {
            statusLabel.string = (connectedPeripheral.name ?? "") + ":\n disconnected"
        } else {
            statusLabel.string = ""
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {}
}


extension ViewController : CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        browser.reloadColumn(1)
        if browser.selectionIndexPath.length == 2 {
            browserAction(browser)
        } else if let services = peripheral.services {
            for service in services {
                if service.UUID == selectedService?.UUID {
                    selectedService = service
                    peripheral.discoverCharacteristics(nil, forService: service)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        browser.reloadColumn(2)
        if browser.selectionIndexPath.length == 3 {
            browserAction(browser)
        } else if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID == selectedCharacteristic?.UUID {
                    selectedCharacteristic = characteristic
                    if characteristic.properties.contains(.Read) {
                        readCharacteristic()
                        
                    }
                    refreshCharacteristicDetail()
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        logViewController?.appendRead(characteristic)
        if characteristic == selectedCharacteristic {
            characteristicUpdatedDate = NSDate()
            refreshCharacteristicDetail()
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        logViewController?.appendWrite(characteristic)
    }
}
