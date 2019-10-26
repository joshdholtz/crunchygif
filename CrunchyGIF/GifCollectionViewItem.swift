//
//  GifCollectionViewItem.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/25/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

struct GifFile {
    let modifiedAt: Date
    let thumbnail: NSImage?
    let fileName: String
    let url: URL
}

class GifCollectionViewItem: NSCollectionViewItem {

    // 1
    var gifFile: GifFile? {
      didSet {
        guard isViewLoaded else { return }
        if let gifFile = gifFile {
          imageView?.image = gifFile.thumbnail
          textField?.stringValue = gifFile.fileName
            
            if let dragImageView = imageView as? DragImageView {
                dragImageView.fileToPaste = gifFile.url
            }
        } else {
          imageView?.image = nil
          textField?.stringValue = ""
            
            if let dragImageView = imageView as? DragImageView {
                dragImageView.fileToPaste = nil
            }
        }
      }
    }
    
    // 2
    override func viewDidLoad() {
      super.viewDidLoad()
      view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }
//
//    override func mouseDown(with event: NSEvent) {
//        guard let fileToPaste = gifFile?.url else {
//            return
//        }
//
//        let draggingItem = NSDraggingItem(pasteboardWriter: fileToPaste as NSURL)
//
//        let image = NSImage(byReferencing: fileToPaste)
//        let bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)
//        draggingItem.setDraggingFrame(bounds, contents:image)
//
//        beginDraggingSession(with: [draggingItem], event: event, source: self)
//    }
}

//extension GifCollectionViewItem: NSDraggingSource {
//    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
//        return .copy
//    }
//
//    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
//        print("completed - \(operation)")
//    }
//}

