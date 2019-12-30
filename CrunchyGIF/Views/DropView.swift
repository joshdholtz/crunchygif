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
    
    typealias OnDrop = (String) -> ()
    typealias OnStart = () -> ()
    typealias OnEnd = () -> ()
    
    var onDrop: OnDrop?
    var onStart: OnStart?
    var onEnd: OnEnd?
    
    var fileToPaste: URL?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor

        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.onStart?()
        if DragTools.checkExtension(sender) == true {
            self.layer?.backgroundColor = NSColor.clear.cgColor
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor.clear.cgColor
        self.onEnd?()
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = NSColor.clear.cgColor
        self.onEnd?()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let path = DragTools.getFilePath(draggingInfo: sender) else {
            return false
        }

        onDrop?(path)

        return true
    }
}
