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
    
    var selectedDevice:Device? = nil
    var selectedService:CBService? = nil
    var selectedCharacteristic:CBCharacteristic? = nil
    var characteristicUpdatedDate:Date? = nil
    let dateFormatter = DateFormatter()
    
    @IBOutlet var browser:NSBrowser!
    @IBOutlet var writeAscii:NSTextField!
    @IBOutlet var writeHex:NSTextField!
    @IBOutlet var readButton:NSButton!
    @IBOutlet var subscribeButton:NSButton!
    @IBOutlet var statusLabel:NSTextField!
    @IBOutlet var statusBarHeightConstraint:NSLayoutConstraint!
    
    var logWindowController:NSWindowController? = nil
    var logViewController:LogViewController? = nil
    var tooltipTagForRow:[Int:NSView.ToolTipTag] = [:]
    var rowForTooltipTag:[NSView.ToolTipTag:Int] = [:]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scanner.delegate = self
        scanner.start()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        browser.separatesColumns = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        setupCharacteristicControls()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject?) {
        if let device = selectedDevice {
            device.disconnect()
        }
        selectedDevice = nil
        selectedService = nil
        scanner.restart()
        resetTooltips()
    }
    
    @IBAction func sortPressed(_ sender: AnyObject?) {
        scanner.devices.sort { return $0.rssi > $1.rssi }
        reloadColumn(0)
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
        case 1: return selectedDevice?.services.count ?? 0
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
            let device = scanner.devices[row]
            cell.title = (device.friendlyName) + "(\(device.rssi))"
            let rect = browser.frame(ofRow: row, inColumn: column)
            if tooltipTagForRow[row] == nil {
                let tag = browser.addToolTip(rect, owner: self, userData: nil)
                tooltipTagForRow[row] = tag
                rowForTooltipTag[tag] = row
            }
        case 1:
            if let service = selectedDevice?.services[row] {
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
    
    func tooltipStringForAdvData(_ advData:[String:Any]) -> String {
        var tooltip = ""
        if let mfgData = advData[CBAdvertisementDataManufacturerDataKey] as? Data {
            tooltip += "Mfg Data:\t\t0x\(mfgData.hexString)\n"
            if mfgData[0] == 0xd9 && mfgData[1] == 0x01 {
                let uidData = mfgData[6..<14]
                tooltip += "UID:\t\t\t\(uidData.hexString)\n"
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
    
    func selectDevice(_ device: Device) {
        if device != selectedDevice {
            selectedDevice?.disconnect()
            selectedDevice?.delegate = nil
            device.delegate = self
            device.connect()
            selectedDevice = device
        }
    }
    
    
    @IBAction
    func browserAction(_ sender:NSBrowser) {
        guard let indexPath = browser.selectionIndexPath else { return }
        let column = indexPath.count
        browser.setTitle(self.browser(browser,titleOfColumn:column)!, ofColumn: column)
        // Automatically reconnect if a service or characteristic is selected.
        if [2,3].contains(column) {
            reconnectPeripheral()
        }
        if column == 1 {
            let device = scanner.devices[indexPath[0]]
            if device != selectedDevice {
               updateStatusLabel(for: device)
            }
            selectDevice(device)
            reloadColumn(1)
        } else if column == 2 {
            if let service = selectedDevice?.services[indexPath[1]] {
                selectedService = service
                selectedDevice?.discoverCharacteristics(for: service)
                selectedCharacteristic = nil
                reloadColumn(2)
            }
        } else if column == 3 {
            if let characteristic = selectedService?.characteristics?[indexPath[2]] {
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
        if let device = selectedDevice, device.peripheral.state != .connected {
            device.connect()
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
      reloadColumn(3)
    }
    
    func reloadColumn(_ column: Int) {
        for row in 0..<browser(browser, numberOfRowsInColumn: column) {
            guard let cell = browser.loadedCell(atRow: row, column: column) as? NSBrowserCell else { continue }
            browser(browser, willDisplayCell: cell, atRow: row, column: column)
        }
        browser.reloadColumn(column)
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
                hex = value.hexString
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
            selectedDevice?.read(characteristic: characteristic)
        }
    }
    
    @IBAction
    func readButtonPressed(_ button:NSButton) {
        readCharacteristic()
    }
    
    @IBAction
    func subscribeButtonPressed(_ button:NSButton) {
        if let characteristic = selectedCharacteristic {
            selectedDevice?.setNotify(true, for: characteristic)
        }
    }
    
    @IBAction
    func hexEntered(_ textField:NSTextField) {
        var bytes = [UInt8]()
        let text = textField.stringValue
        if text.count % 2 != 0 {
            textField.shake()
            return
        }
        var i = text.startIndex
        while i < text.endIndex {
            let nextIndex = text.index(i, offsetBy: 2)
            let hexByte = text[i ..< nextIndex]
            if let byte:UInt8 = UInt8(hexByte, radix:16) {
                bytes.append(byte)
            } else {
                textField.shake()
                return
            }
            i = nextIndex
        }
        let data = Data(bytes)
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
            
            
            selectedDevice?.write(data: data, for: characteristic, type: writeType)
            
            logViewController?.appendWrite(characteristic, data: data)
        }
    }
    
    func appendLog(_ message:String) {
        logViewController?.logText.textStorage?.append(NSAttributedString(string:message + "\n"))
        logViewController?.logText.scrollToEndOfDocument(self)
    }
    
    func updateStatusLabel(for device: Device) {
        if device == selectedDevice {
            statusLabel.stringValue = "\(device.friendlyName): \(device.peripheral.state == .connected ? "connected" : "disconnected")"
            
            NSAnimationContext.runAnimationGroup({context in
                context.duration = 0.25
                context.allowsImplicitAnimation = true
                
                statusBarHeightConstraint.isActive = false
                self.view.layoutSubtreeIfNeeded()
              
            }, completionHandler:nil)
        } else {
            statusLabel.stringValue = ""
            NSAnimationContext.runAnimationGroup({context in
                context.duration = 0.25
                context.allowsImplicitAnimation = true
                
                statusBarHeightConstraint.isActive = true
                self.view.layoutSubtreeIfNeeded()
              
            }, completionHandler:nil)
        }
    }
}

extension ViewController: NSViewToolTipOwner {
    
    func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String {
        if let row = rowForTooltipTag[tag] {
            let device = scanner.devices[row]
            return tooltip(for: device)
        }
        return ""
    }
    
    func tooltip(for device: Device) -> String {
        var tooltipParts:[String] = []
        tooltipParts.append("identifier:\t\t\(device.peripheral.identifier)")
        let advData = device.advertisingData
        tooltipParts.append(tooltipStringForAdvData(advData))
        return tooltipParts.joined(separator: "\n")
    }
}

extension ViewController : PasteboardBrowserDelegate {
    func browser(_ browser: PasteboardBrowser, pasteboardStringFor indexPath: IndexPath) -> String? {
        if indexPath.count == 1 {
            let row = indexPath[0]
            guard let tag = tooltipTagForRow[row] else {return nil}
            let peripheralName = scanner.devices[row].friendlyName
            return "Name:\t\t\t\(peripheralName)\n" + self.view(browser, stringForToolTip: tag, point: NSPoint(), userData: nil)
        }
        return nil
    }
    
    func browser(_ browser: PasteboardBrowser, menuFor cell: NSBrowserCell, atRow row: Int, column: Int) -> NSMenu? {
        let menu = NSMenu()
        let copyItem = NSMenuItem(title: "Copy", action: #selector(copyCellContents(sender:)), keyEquivalent: "")
        menu.addItem(copyItem)
        
        if column == 0 {
            menu.addItem(NSMenuItem(title: "Copy Device Identifier", action: #selector(copyDeviceIdentifier(sender:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Copy Device Tooltip", action: #selector(copyDeviceTooltip(sender:)), keyEquivalent: ""))
        } else if column == 1 {
            menu.addItem(NSMenuItem(title: "Copy Service UUID", action: #selector(copyServiceUUID(sender:)), keyEquivalent: ""))
        } else if column == 2 {
            menu.addItem(NSMenuItem(title: "Copy Characteristic UUID", action: #selector(copyCharacteristicUUID(sender:)), keyEquivalent: ""))
        }
        
        return menu
    }
    
    @IBAction
    func copyCellContents(sender: Any) {
        guard let cell = browser.selectedCell() as? NSBrowserCell else { return }
        
        putPasteboardString(cell.title)
    }
    
    @IBAction
    func copyDeviceIdentifier(sender: Any) {
        guard let deviceIdentifier = selectedDevice?.peripheral.identifier else { return }
        
        putPasteboardString(deviceIdentifier.uuidString)
    }
    
    @IBAction
    func copyDeviceTooltip(sender: Any) {
        guard let device = selectedDevice else { return }
        
        putPasteboardString(tooltip(for: device))
    }
    
    @IBAction
    func copyServiceUUID(sender: Any) {
        guard let serviceUUID = selectedService?.uuid else { return }
        
        putPasteboardString(serviceUUID.uuidString)
    }
    
    @IBAction
    func copyCharacteristicUUID(sender: Any) {
        guard let characteristicUUID = selectedCharacteristic?.uuid else { return }
        
        putPasteboardString(characteristicUUID.uuidString)
    }
    
    
    private func putPasteboardString(_ string: String) {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: self)
        pb.setString(string, forType: .string)
    }
}

extension ViewController : ScannerDelegate {
    func scanner(_ scanner: Scanner, didUpdateDevices: [Device]) {
        reloadColumn(0)
    }
}

extension ViewController : DeviceDelegate {
    func deviceDidConnect(_ device: Device) {
        updateStatusLabel(for: device)
    }
    
    func deviceDidDisconnect(_ device: Device) {
        updateStatusLabel(for: device)
    }
    
    func deviceDidUpdateName(_ device: Device) {
        updateStatusLabel(for: device)
        guard let deviceIndex = scanner.devices.firstIndex(of: device) else { return }
        browser.reloadData(forRowIndexes: IndexSet(integer: deviceIndex), inColumn: 0)
    }
    
    func device(_ device: Device, updated services: [CBService]) {
        reloadColumn(1)
        if browser.selectionIndexPath?.count == 2 {
            browserAction(browser)
        } else {
            for service in services {
                if service.uuid == selectedService?.uuid {
                    selectedService = service
                    device.discoverCharacteristics(for: service)
                }
            }
        }
    }
    
    func device(_ device: Device, updated characteristics: [CBCharacteristic], for service: CBService) {
        reloadColumn(2)
        if browser.selectionIndexPath?.count == 3 {
            browserAction(browser)
        } else  {
            for characteristic in characteristics {
                if characteristic.uuid == selectedCharacteristic?.uuid {
                    selectedCharacteristic = characteristic
                    if characteristic.properties.contains(.read) {
                        device.read(characteristic: characteristic)
                        
                    }
                    refreshCharacteristicDetail()
                }
            }
        }
    }
    
    func device(_ device: Device, updatedValueFor characteristic: CBCharacteristic) {
        logViewController?.appendRead(characteristic)
        if characteristic == selectedCharacteristic {
            characteristicUpdatedDate = Date()
            refreshCharacteristicDetail()
        }
    }
}
