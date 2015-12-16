//
//  PasteboardBrowser.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/16/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

class PasteboardBrowser: NSBrowser {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction
    func copy(sender:AnyObject) {
        if let cell = self.selectedCell() as? NSBrowserCell {
            let text = cell.title
            let pb = NSPasteboard.generalPasteboard()
            pb.declareTypes([NSStringPboardType], owner: self)
            pb.setString(text, forType: NSStringPboardType)
        }
    }
    
}
