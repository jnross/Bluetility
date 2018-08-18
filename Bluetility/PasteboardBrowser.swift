//
//  PasteboardBrowser.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/16/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

protocol IndexPathPasteboardDelegate {
    func pasteboardStringForIndexPath(_ indexPath:IndexPath) -> String?
}

class PasteboardBrowser: NSBrowser {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction
    func copy(_ sender:AnyObject) {
        var string:String? = nil
        if let pasteboardDelegate = self.delegate as? IndexPathPasteboardDelegate {
            string = pasteboardDelegate.pasteboardStringForIndexPath(self.selectionIndexPath!)
        }
        if string == nil {
            string = (self.selectedCell() as? NSBrowserCell)?.title
        }
        guard let pasteString = string else {return}
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: self)
        pb.setString(pasteString, forType: .string)
    }
    
}
