//
//  MovDocument.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 1/6/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import Foundation
import Cocoa

class MovDocument: NSDocument {
    static let newMovDocument = Notification.Name("new-mov-document")
    
    override func read(from url: URL, ofType typeName: String) throws {
        let fileNameAndExtension = url.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let fileExtension = url.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")
        
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!

        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampPath = cachesPath.appendingPathComponent("movs").appendingPathComponent("\(timestamp)")

        try? FileManager.default.createDirectory(at: timestampPath, withIntermediateDirectories: true, attributes: nil)

        let pathIn = timestampPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        
        fileURL = pathIn
        try FileManager.default.copyItem(at: url, to: pathIn)
        NotificationCenter.default.post(name: MovDocument.newMovDocument, object: pathIn)
    }
}
