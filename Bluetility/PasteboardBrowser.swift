//
//  PasteboardBrowser.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/16/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

protocol IndexPathPasteboardDelegate {
    func pasteboardStringForIndexPath(indexPath:NSIndexPath) -> String?
}

class PasteboardBrowser: NSBrowser {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction
    func copy(sender:AnyObject) {
        var string:String? = nil
        if let pasteboardDelegate = self.delegate as? IndexPathPasteboardDelegate {
            string = pasteboardDelegate.pasteboardStringForIndexPath(self.selectionIndexPath)
        }
        if string == nil {
            string = (self.selectedCell() as? NSBrowserCell)?.title
        }
        guard let pasteString = string else {return}
        let pb = NSPasteboard.generalPasteboard()
        pb.declareTypes([NSStringPboardType], owner: self)
        pb.setString(pasteString, forType: NSStringPboardType)
    }
    
}
