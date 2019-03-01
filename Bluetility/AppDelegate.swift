//
//  AppDelegate.swift
//  Bluetility
//
//  Created by Joseph Ross on 11/9/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let defaults = ["NSToolTipAutoWrappingDisabled" : NSNumber(value: true as Bool)]
        UserDefaults.standard.register(defaults: defaults)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}

