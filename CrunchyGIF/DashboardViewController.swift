//
//  DashboardViewController.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/21/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

class DashboardViewController: NSViewController {
    
    @IBOutlet var dropView: DropView!
    
    var processMeta: (Process, DispatchWorkItem)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//        let path = desktopPath.appendingPathComponent("text").appendingPathExtension("txt")
//
//        let queue = OperationQueue.main
//
//        let scope = desktopPath.startAccessingSecurityScopedResource()
//        print("scope: \(scope)")
        
//        let intent = NSFileAccessIntent.writingIntent(with: path, options: .forReplacing)
//        let filec = NSFileCoordinator()
//        filec.coordinate(with: [intent], queue: queue) { (error) in
//            print("error??? - \(error)")
//
//            let data = "hello".data(using: .utf8)
//            let success = FileManager.default.createFile(atPath: path.absoluteString, contents: data, attributes: [:])
//            print("success: \(success)")
//
//            if scope {
//                path.stopAccessingSecurityScopedResource()
//            }
//        }
        
        dropView.onDrop = onDrop
    }
    
    func onDrop(path: String) {
        
        print("Path: \(path)")
        let path = URL(fileURLWithPath: path)
        let fileNameAndExtension = path.lastPathComponent
        let fileExtension = path.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")
        
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let randomName = UUID().uuidString
        
        let pathIn = cachesPath.appendingPathComponent(randomName).appendingPathExtension(fileExtension)
        let pathOut = cachesPath.appendingPathComponent(randomName).appendingPathExtension("gif")
        
        
        let pathFinal = desktopPath.appendingPathComponent(fileName).appendingPathExtension("gif")
        
        do {
            print("fileNameAndExtension: \(fileNameAndExtension)")
            print("fileExtension: \(fileExtension)")
            print("fileName: \(fileName)")
            print("pathFinal: \(pathFinal)")
            try FileManager.default.copyItem(at: path, to: pathIn)
            
            toGif(pathIn: pathIn, pathOut: pathOut) { [weak self] in
                self?.dropView.fileToPaste = pathOut
//                try! FileManager.default.copyItem(at: pathOut, to: pathFinal)
            }
        } catch {
            print("Whoops: \(error)")
        }
    }
}

extension DashboardViewController {
    func toGif(pathIn: URL, pathOut: URL, done: @escaping () -> ()) {
        // ffmpeg -i yesbuddy.mov -pix_fmt rgb24 output.gif
        
        // ffmpeg -ss 00:00:00.000 -i yesbuddy.mov -pix_fmt rgb24 -r 10 -s 320x240 -t 00:00:10.000 output.gif

        // Shrink with image magic
        // convert -layers Optimize output.gif output_optimized.gif
        
        // get URL to the the documents directory in the sandbox
        let desktopUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        print("desktopUrl: \(desktopUrl)")
        
        let files = try! FileManager.default.contentsOfDirectory(at: desktopUrl, includingPropertiesForKeys: nil, options: [])
        for file in files {
            print("file: \(file)")
        }

        // add a filename
//        let fileUrl = documentsUrl.URLByAppendingPathComponent("foo.txt")

        print("Lets start to gif")
        
        let arguments = [
            "-i",
            pathIn.absoluteString,
            "-pix_fmt",
            "rgb24",
            pathOut.absoluteString
        ]
        
        processMeta = GifTools.createFFMPEGProcess(arguments: arguments) { (terminated) in
            print("terminated: \(terminated)")
            done()
        }
    }
}

extension DashboardViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> DashboardViewController {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier("DashboardViewController")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? DashboardViewController else {
            fatalError("Why cant i find DashboardViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
