//
//  GifOperation.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 1/6/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import Foundation

import mobileffmpeg

class GifOperation: AsynchOperation {
    
    private let path: URL
    private let filter: String
    
    init(path: URL, filter: String) {
        self.path = path
        self.filter = filter
    }
    
    override func main() {
        // Path stuff
        let fileNameAndExtension = path.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let fileExtension = path.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")

        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.joshholtz.CrunchyGIF")!

        let uuid = UUID().uuidString
        let uuidPath = containerURL.appendingPathComponent("gifs").appendingPathComponent("\(uuid)")

        try? FileManager.default.createDirectory(at: uuidPath, withIntermediateDirectories: true, attributes: nil)

        let pathIn = uuidPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        let pathOut = uuidPath.appendingPathComponent(fileName).appendingPathExtension("gif")
        
        do {
            try FileManager.default.copyItem(at: path, to: pathIn)
            
            sleep(1)

            toGif(filter: filter, pathIn: pathIn, pathOut: pathOut) { [weak self] in
                try? FileManager.default.removeItem(at: pathIn)

                DispatchQueue.main.async { [weak self] in
                    self?.finish()
                }
            }
        } catch {
            print("Whoops: \(error)")
            finish()
        }
    }
    
    func toGif(filter: String, pathIn: URL, pathOut: URL, done: @escaping () -> ()) {
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tempPath = cachesPath.appendingPathComponent("tmp")
        
        try? FileManager.default.createDirectory(at: tempPath, withIntermediateDirectories: true, attributes: nil)

        let paletteTemp = tempPath.appendingPathComponent("palette.png")
        
        // https://cassidy.codes/blog/2017/04/25/ffmpeg-frames-to-gif-optimization/
        
        let argumentsPalette = [
            "-v",
            "warning",
            "-i",
            pathIn.absoluteString,
            "-vf",
            "\(filter),palettegen=stats_mode=diff",
            "-y",
            paletteTemp.absoluteString
        ]
        
        let argumentsWithPalette = [
            "-i",
            pathIn.absoluteString,
            "-i",
            paletteTemp.absoluteString,
            "-lavfi",
            "\(filter),paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle",
            "-y",
            pathOut.absoluteString
        ]
        
        let rc1 = MobileFFmpeg.execute(withArguments: argumentsPalette)
        let rc2 = MobileFFmpeg.execute(withArguments: argumentsWithPalette)
        
        print("rc1: \(rc1)")
        print("rc2: \(rc2)")
        
        done()
    }
}
