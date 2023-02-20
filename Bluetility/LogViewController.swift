//
//  LogViewController.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/29/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa
import CoreBluetooth

class LogViewController: NSViewController, LogRecorderDelegate {
    
    var recorder: LogRecorder? = nil {
        didSet {
            recorder?.delegate = self
            logText.string = recorder?.lines.joined(separator: "\n") ?? ""
        }
    }
    @IBOutlet var logText:NSTextView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func appendLogText(_ message:String) {
        logText.string.append(message + "\n")
        logText.scrollToEndOfDocument(self)
    }
    
    @IBAction func clearLogPressed(_ sender:NSButton) {
        recorder?.reset()
    }
    
    @IBAction func saveCSVPressed(_ sender:NSButton) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["txt"]
        savePanel.beginSheetModal(for: self.view.window!) { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                savePanel.orderOut(self)
                if let selectedUrl = savePanel.url {
                    let contents:String = self.logText.string
                    do {
                        try contents.write(to: selectedUrl, atomically: true, encoding: String.Encoding.utf8)
                    } catch {
                        //TODO: Display error to user
                    }
                }
            }
        }
    }
    
    
    func recorder(_ recorder: LogRecorder, appendedLine: String) {
        appendLogText(appendedLine)
    }
    
    func recorderDidReset(_ recorder: LogRecorder) {
        logText.string = ""
    }
    
}
