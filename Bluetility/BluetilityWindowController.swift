//
//  BluetilityWindowController.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa
import Logging

class BluetilityWindowController: NSWindowController {

    var viewController:ViewController?
    @IBOutlet var refreshItem: NSToolbarItem!
    @IBOutlet var sortItem: NSToolbarItem!
    @IBOutlet var logItem: NSToolbarItem!
    @IBOutlet var searchItemField: NSSearchField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.shouldCascadeWindows = false
        window?.setFrameAutosaveName("bluetility")
    
        let recorder = LogRecorder()
        LoggingSystem.bootstrap { label in
            return BluetilityLogHandler(label: label, recorder: recorder)
        }
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        viewController = self.contentViewController as? ViewController
        viewController?.recorder = recorder
        logItem.target = viewController
        sortItem.target = viewController
        refreshItem.target = viewController
        logItem.action = #selector(ViewController.logPressed(_:))
        sortItem.action = #selector(ViewController.sortPressed(_:))
        refreshItem.action = #selector(ViewController.refreshPressed(_:))
        searchItemField.delegate = self
    }
}

extension BluetilityWindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let searchField = obj.object as? NSSearchField, searchField == searchItemField else {
            return
        }
        
        viewController?.searchTextDidChange(value: searchField.stringValue)
    }
}

