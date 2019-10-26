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
    
    @IBOutlet var overView: NSView!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var gifFiles: [GifFile] = []
    var processMeta: (Process, DispatchWorkItem)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        overView.wantsLayer = true
        overView.layer?.backgroundColor = NSColor.red.cgColor
        dropView.onDrop = onDrop
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        reloadImages()
    }
    
    func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.layer?.backgroundColor = NSColor.black.cgColor
        
        collectionView.register(GifCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GifCollectionViewItem"))
    }
    
    func reloadImages() {
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
//            let gifUrls = try FileManager.default.contentsOfDirectory(at: cachesPath, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
        
        let enumerator = FileManager.default.enumerator(at: cachesPath,
                                includingPropertiesForKeys: [.contentModificationDateKey],
                                                   options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        gifFiles = enumerator.compactMap({ (value) -> GifFile? in
            guard let url = value as? URL, url.lastPathComponent.contains(".gif") else {
                return nil
            }
            
            let modifiedAt = (try? url.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate) ?? Date.distantPast
            
            return GifFile(
                modifiedAt: modifiedAt,
                thumbnail: NSImage(byReferencing: url),
                fileName: url.lastPathComponent,
                url: url)
        }).sorted(by: { $0.modifiedAt > $1.modifiedAt })
        
        collectionView.reloadData()
    }
    
    
    func onDrop(path: String) {
        let path = URL(fileURLWithPath: path)
        let fileNameAndExtension = path.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let fileExtension = path.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")
        
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampPath = cachesPath.appendingPathComponent("\(timestamp)")
        
        try? FileManager.default.createDirectory(at: timestampPath, withIntermediateDirectories: true, attributes: nil)
        
        let pathIn = timestampPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        let pathOut = timestampPath.appendingPathComponent(fileName).appendingPathExtension("gif")
        
        do {
            try FileManager.default.copyItem(at: path, to: pathIn)
            
            toGif(pathIn: pathIn, pathOut: pathOut) { [weak self] in
                try? FileManager.default.removeItem(at: pathIn)
                self?.dropView.fileToPaste = pathOut
                
                DispatchQueue.main.async { [weak self] in
                    self?.reloadImages()
                }
//                try! FileManager.default.copyItem(at: pathOut, to: pathFinal)
            }
        } catch {
            print("Whoops: \(error)")
        }
    }
}

extension DashboardViewController : NSCollectionViewDataSource {
    // 1
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    // 2
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifFiles.count
    }

    // 3
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        // 4
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GifCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? GifCollectionViewItem else {return item}

        // 5
        let gifFile = gifFiles[indexPath.item]
        collectionViewItem.gifFile = gifFile
        return item
    }
}

extension DashboardViewController {
    func toGif(pathIn: URL, pathOut: URL, done: @escaping () -> ()) {
        // ffmpeg -i yesbuddy.mov -pix_fmt rgb24 output.gif
        
        // ffmpeg -ss 00:00:00.000 -i yesbuddy.mov -pix_fmt rgb24 -r 10 -s 320x240 -t 00:00:10.000 output.gif

        // Shrink with image magic
        // convert -layers Optimize output.gif output_optimized.gif

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
