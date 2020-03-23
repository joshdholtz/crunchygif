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

    var size: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let fileSize = attributes[FileAttributeKey.size] as? UInt64 else {
                return ""
        }

        // KB
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.0f KB", floatSize)
        }
        // MB
        floatSize = floatSize / 1024
        if floatSize < 1023 {
            return String(format: "%.1f MB", floatSize)
        }
        // GB
        floatSize = floatSize / 1024
        return String(format: "%.1f GB", floatSize)
    }
}

class GifCollectionViewItem: NSCollectionViewItem {
    
    var gifFile: GifFile? {
        didSet {
            guard isViewLoaded else { return }
            if let gifFile = gifFile {
                imageView?.image = gifFile.thumbnail
                textField?.stringValue = gifFile.fileName + " " + "(\(gifFile.size))"
                
                
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
