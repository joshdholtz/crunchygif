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
    
//    var viewController: ViewController? {
//        return windowControllers.first?.contentViewController
//            as? ViewController
//    }
    
    enum Ugh: Error {
        case dude
    }
    
    
    override func read(from data: Data, ofType typeName: String) throws {
        
        
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!

        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampPath = cachesPath.appendingPathComponent("gifs").appendingPathComponent("\(timestamp)")

        try? FileManager.default.createDirectory(at: timestampPath, withIntermediateDirectories: true, attributes: nil)

        let fileName = "josh"
        let fileExtension = "mov"
        let pathIn = timestampPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)

        do {
            try data.write(to: pathIn)
//            try FileManager.default.copyItem(at: path, to: pathIn)

//            toGif(filter: filter, pathIn: pathIn, pathOut: pathOut) { [weak self] in
//                try? FileManager.default.removeItem(at: pathIn)
//
//                DispatchQueue.main.async { [weak self] in
//                    self?.finish()
//                }
//            }
        } catch {
            debugPrint("Whoops: \(error)")
//            finish()
        }
        
        NotificationCenter.default.post(name: MovDocument.newMovDocument, object: self)
    }
    
    
}
