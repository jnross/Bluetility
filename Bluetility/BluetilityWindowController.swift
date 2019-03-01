//
//  BluetilityWindowController.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

class BluetilityWindowController: NSWindowController {

    @IBOutlet var viewController:ViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.shouldCascadeWindows = false
        window?.setFrameAutosaveName("bluetility");
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    @IBAction func refreshPressed(_ sender: AnyObject?) {
    }
}
