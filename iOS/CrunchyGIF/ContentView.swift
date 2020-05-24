//
//  ContentView.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 5/22/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import SwiftUI

import AVFoundation
import MobileCoreServices
import SDWebImageSwiftUI

private let gifQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "GIF queue"
    return queue
}()

struct ContentView: View {
    
    @State var gifFiles: [GifFile] = []
    
    let dropDelegate = MyDropDelegate()
    
    let maxImageWidth: CGFloat = 400
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                if !self.gifFiles.isEmpty {
                    ScrollView {
                        ForEach(self.gifFiles.chunked(into: max(Int(geometry.size.width / self.maxImageWidth), 1)).map({ (gifs) -> GifRow in
                            return GifRow(gifs: gifs)
                        })) { row in
                            HStack {
                                ForEach(row.gifs) { file in
                                    Group {
                                        AnimatedImage(url: file.url)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .contextMenu {
                                                Button(action: {
                                                    try? FileManager.default.removeItem(at: file.url)
                                                    self.reloadImages()
                                                }) {
                                                    Text("Delete")
                                                    Image(systemName: "x.circle.fill")
                                                }
                                            }
                                    }.frame(minWidth: 100, maxWidth: self.maxImageWidth)
                                        
                                }
                            }
                            Divider()
                        }
                    }
                }
            }.padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image("PatternBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.7)
                .edgesIgnoringSafeArea(.all)
        )
        .onDrop(of: [kUTTypeMovie as String], delegate: self.dropDelegate)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.reloadImages()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.GIFComplete)) { _ in
            if gifQueue.operationCount == 0 {
                self.reloadImages()
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.reloadImages()
            }
        }
    }
    
    func reloadImages() {
        DispatchQueue.init(label: "background").async {
            let containerURL =
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.joshholtz.CrunchyGIF")
            let cachesPath = containerURL!
                   
                   let enumerator = FileManager.default.enumerator(at: cachesPath,
                                           includingPropertiesForKeys: [.contentModificationDateKey],
                                                              options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                       print("directoryEnumerator error at \(url): ", error)
                                                                       return true
                   })!
                   
            let gifFiles = enumerator.compactMap({ (value) -> GifFile? in
                       guard let url = value as? URL, url.lastPathComponent.contains(".gif") else {
                           return nil
                       }
                       
                       let modifiedAt = (try? url.resourceValues(
                           forKeys: [.contentModificationDateKey]
                       ).contentModificationDate) ?? Date.distantPast
                       
                       return GifFile(
                           modifiedAt: modifiedAt,
                           thumbnail: self.resizedImage(at: url, for: CGSize(width: 600, height: 600)),
                           fileName: url.lastPathComponent,
                           url: url)
                   }).sorted(by: { $0.modifiedAt > $1.modifiedAt })
            
            DispatchQueue.main.async {
                self.gifFiles = gifFiles
                print("FILES COUNT: \(self.gifFiles.count)")
            }
        }
    }
    
    func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        else {
            return nil
        }

        return UIImage(cgImage: image)
    }
}

struct GifRow: Identifiable {
    let gifs: [GifFile]
    let id = UUID().uuidString
}

struct GifFile {
    let modifiedAt: Date
    let thumbnail: UIImage?
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

extension GifFile: Identifiable {
    var id: String {
        return url.absoluteString
    }
}
struct MyDropDelegate: DropDelegate {
    func validateDrop(info: DropInfo) -> Bool {
        print("Validate drop")
        return info.hasItemsConforming(to: [kUTTypeMovie as String])
    }
    
    func dropEntered(info: DropInfo) {
        print("Drop entered")
    }
    
    func performDrop(info: DropInfo) -> Bool {
        
        let itemProviders = info.itemProviders(for: [kUTTypeMovie as String])
        for item in itemProviders {
            item.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { (url, error) in
                
                if let url = url {
                    do {
                        let uuid = UUID().uuidString
                        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid)")
                        try FileManager.default.moveItem(at: url, to: tempUrl)
                        
                        let filter = "fps=\(10),scale=\(400):\(-1):flags=lanczos"
                        let operation = GifOperation(path: tempUrl, filter: filter)
                        
                        let doneOperation = BlockOperation {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name.GIFComplete, object: nil)
                            }
                        }
                        doneOperation.addDependency(operation)
                        
                        gifQueue.addOperations([operation, doneOperation], waitUntilFinished: false)
                    } catch {
                        print("ERROR: \(error)")
                    }
                }
                
            }
        }

        return true

    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return nil
    }
    
    func dropExited(info: DropInfo) {

    }
}
