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
    func menu(for cell: NSBrowserCell, at indexPath: IndexPath) -> NSMenu?
}

class PasteboardBrowser: NSBrowser {
    
    @IBAction
    func copy(_ sender:AnyObject) {
        var string:String? = nil
        if  let pasteboardDelegate = self.delegate as? IndexPathPasteboardDelegate,
            let indexPath = self.selectionIndexPath
        {
            string = pasteboardDelegate.pasteboardStringForIndexPath(indexPath)
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
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = event.locationInWindow
        var row: Int = 0
        var column: Int = 0
        guard getRow(&row, column: &column, for: point) else { return nil }
        selectRow(row, inColumn: column)
        self.sendAction()
        
        guard
            let cell = selectedCell() as? NSBrowserCell,
            let indexPath = selectionIndexPath,
            let delegate = delegate as? IndexPathPasteboardDelegate
        else {
           return nil
        }
        return delegate.menu(for: cell, at: indexPath)
    }
    
}
