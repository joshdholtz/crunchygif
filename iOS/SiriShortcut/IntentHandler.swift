//
//  IntentHandler.swift
//  SiriShortcut
//
//  Created by Josh Holtz on 5/23/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import Intents

import MobileCoreServices
import mobileffmpeg

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        
        
        return self
    }
    
}

class ConvertVideoIntentHandler: NSObject, ConvertVideoIntentHandling {
    func handle(intent: ConvertVideoIntent, completion: @escaping (ConvertVideoIntentResponse) -> Void) {
        
        guard let file = intent.file, let path = file.fileURL else {
            completion(ConvertVideoIntentResponse.init(code: ConvertVideoIntentResponseCode.failure, userActivity: nil))
            return
        }

        // Path stuff
        let fileNameAndExtension = path.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let fileExtension = path.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")

        let fileManager = FileManager.default
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let pathOut = tempUrl.appendingPathComponent(UUID().uuidString).appendingPathExtension("gif")
        let pathIn = path
        
        // Filter
        let filter = "fps=\(10),scale=\(400):\(-1):flags=lanczos"
        
        // zip stuff
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tempPath = cachesPath.appendingPathComponent("tmp")
        
        try? FileManager.default.createDirectory(at: tempPath, withIntermediateDirectories: true, attributes: nil)

        let paletteTemp = tempPath.appendingPathComponent("palette-\(UUID().uuidString).png")
        
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
        
//        let rc1 = MobileFFmpeg.execute(withArguments: argumentsPalette)
//        let rc2 = MobileFFmpeg.execute(withArguments: argumentsWithPalette)
        
//        print("rc1: \(rc1)")
//        print("rc2: \(rc2)")
        
        // completion
        
        let outFile = INFile(fileURL: pathOut, filename: file.filename, typeIdentifier: kUTTypeGIF as String)
        completion(ConvertVideoIntentResponse.success(file: outFile))
    }
    
    func resolveFile(for intent: ConvertVideoIntent, with completion: @escaping (INFileResolutionResult) -> Void) {
        
        guard let file = intent.file else {
            completion(INFileResolutionResult.needsValue())
            return
        }
        completion(INFileResolutionResult.success(with: file))
    }
    
    func resolveFps(for intent: ConvertVideoIntent, with completion: @escaping (ConvertVideoFpsResolutionResult) -> Void) {
        
        let fps = intent.fps?.intValue ?? 15
        completion(ConvertVideoFpsResolutionResult.success(with: fps))
    }
}

extension ConvertVideoIntentHandler {
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
