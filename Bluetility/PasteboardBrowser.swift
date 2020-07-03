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
    
    override func reloadData(forRowIndexes rowIndexes: IndexSet, inColumn column: Int) {
        for rowIndex in rowIndexes {
            guard let cell = loadedCell(atRow: rowIndex, column: column) else { continue }
            delegate?.browser?(self, willDisplayCell: cell, atRow: rowIndex, column: column)
        }
    }
    
}
