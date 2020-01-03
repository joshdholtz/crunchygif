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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        textField?.lineBreakMode = .byTruncatingMiddle
    }
}
