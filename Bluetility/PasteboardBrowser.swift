//
//  PasteboardBrowser.swift
//  Bluetility
//
//  Created by Joseph Ross on 12/16/15.
//  Copyright © 2015 Joseph Ross. All rights reserved.
//

import Cocoa

protocol PasteboardBrowserDelegate {
    func browser(_ browser: PasteboardBrowser, pasteboardStringFor indexPath: IndexPath) -> String?
    func browser(_ browser: PasteboardBrowser, menuFor cell: NSBrowserCell, atRow row: Int, column: Int) -> NSMenu?
}

class PasteboardBrowser: NSBrowser {
    
    @IBAction
    func copy(_ sender:AnyObject) {
        var string:String? = nil
        if  let pasteboardDelegate = self.delegate as? PasteboardBrowserDelegate,
            let indexPath = self.selectionIndexPath
        {
            string = pasteboardDelegate.browser(self, pasteboardStringFor: indexPath)
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
            let delegate = delegate as? PasteboardBrowserDelegate
        else {
           return nil
        }
        return delegate.browser(self, menuFor: cell, atRow: row, column: column)
    }
    
}
