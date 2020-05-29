//
//  DragImageView.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/25/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

class DragImageView: NSImageView {
    
    var fileToPaste: URL?

    override func mouseDown(with event: NSEvent) {
        guard let fileToPaste = fileToPaste else {
            return
        }

        let draggingItem = NSDraggingItem(pasteboardWriter: fileToPaste as NSURL)
        
        let image = NSImage(byReferencing: fileToPaste)
        let bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)
        draggingItem.setDraggingFrame(bounds, contents:image)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension DragImageView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        print("completed - \(operation)")
    }
}
