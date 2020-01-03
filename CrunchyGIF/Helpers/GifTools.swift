//
//  GifTools.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/23/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

struct GifTools {

    // You can also intercept console output from the process or interrupt the process when problem occurred.
    // https://crowjdh.blogspot.com/2017/05/use-ffmpeg-in-xcodefor-macos.html
    static func createFFMPEGProcess(arguments: [String], callback: @escaping (Bool) -> Void) -> (Process, DispatchWorkItem)? {
        
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else {
            print("Cannot find ffmpeg")
            return nil
        }
        let process = Process()
        let task = DispatchWorkItem {
            process.launchPath = launchPath
            process.arguments = arguments
            process.standardInput = FileHandle.nullDevice
            process.launch()
            process.terminationHandler = { process in
                callback(process.terminationStatus == 0)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
        
        return (process, task)
    }
    
}
