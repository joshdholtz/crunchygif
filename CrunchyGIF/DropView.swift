//
//  DropView.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/23/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

// https://stackoverflow.com/a/34278766
class DropView: NSView {

    let expectedExt = ["mov"]  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
    
    typealias OnDrop = (String) -> ()
    var onDrop: OnDrop?
    
    var fileToPaste: URL?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.red.cgColor

        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.layer?.backgroundColor = NSColor.gray.cgColor
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String
        else { return false }

        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
            }
        }
        return false
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor.red.cgColor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = NSColor.red.cgColor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }

        onDrop?(path)

        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let fileToPaste = fileToPaste else {
            return
        }

        let draggingItem = NSDraggingItem(pasteboardWriter: fileToPaste as NSURL)
        draggingItem.setDraggingFrame(self.bounds, contents:snapshot)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension DropView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        print("completed - \(operation)")
    }
}

extension NSView {
  var snapshot: NSImage {
    guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return NSImage() }
    bitmapRep.size = bounds.size
    cacheDisplay(in: bounds, to: bitmapRep)
    let image = NSImage(size: bounds.size)
    image.addRepresentation(bitmapRep)
    return image
  }
}
