//
//  BluetilityWindowController.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

class BluetilityWindowController: NSWindowController {

    var viewController:ViewController?
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var refreshItem: NSToolbarItem!
    @IBOutlet var sortItem: NSToolbarItem!
    @IBOutlet var logItem: NSToolbarItem!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.shouldCascadeWindows = false
        window?.setFrameAutosaveName("bluetility")
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        viewController = self.contentViewController as? ViewController
        viewController?.statusLabel = statusLabel
        logItem.target = viewController
        sortItem.target = viewController
        refreshItem.target = viewController
        logItem.action = #selector(ViewController.logPressed(_:))
        sortItem.action = #selector(ViewController.sortPressed(_:))
        refreshItem.action = #selector(ViewController.refreshPressed(_:))
        
    }
}
