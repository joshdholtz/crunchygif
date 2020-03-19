//
//  DragTools.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 12/30/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

struct DragTools {
    static let expectedExt = ["mov", "mp4", "m4v", "avi"]
    
    static func getFilePaths(draggingInfo: NSDraggingInfo) -> [String] {
        let pasteboard = draggingInfo.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray
        
        return pasteboard as? [String] ?? []
    }
    
    static func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String
        else { return false }

        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix.lowercased() {
                return true
            }
        }
        return false
    }
}
