//
//  DashboardViewController.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/21/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa
import ImageIO

class DashboardViewController: NSViewController {
    
    @IBOutlet var navigationBar: NSView!
    @IBOutlet var dropView: DropView!
    @IBOutlet var contentView: NSView!
    @IBOutlet var overView: NSView!
    @IBOutlet var crunchBackgroundImageView: NSImageView!
    @IBOutlet var crunchLogoImageView: NSImageView!
    
    @IBOutlet var settingsButton: NSButton!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var isDropping = false
    
    var gifFiles: [GifFile] = []
    var processMeta: (Process, DispatchWorkItem)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        settingsButton.appearance = NSAppearance.current
        settingsButton.contentTintColor = NSColor.lightGray
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Delete All Gifs", action: #selector(deleteAllGifs(_:)), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "P"))
        settingsButton.menu = menu
        
        navigationBar.wantsLayer = true
        navigationBar.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        overView.wantsLayer = true
        overView.layer?.backgroundColor = NSColor.gray.cgColor
        
        dropView.onStart = onDropStart
        dropView.onEnd = onDropEnd
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
        DispatchQueue.init(label: "background").async { [unowned self] in
            let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                   
                   let enumerator = FileManager.default.enumerator(at: cachesPath,
                                           includingPropertiesForKeys: [.contentModificationDateKey],
                                                              options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                       print("directoryEnumerator error at \(url): ", error)
                                                                       return true
                   })!
                   
            self.gifFiles = enumerator.compactMap({ (value) -> GifFile? in
                       guard let url = value as? URL, url.lastPathComponent.contains(".gif") else {
                           return nil
                       }
                       
                       let modifiedAt = (try? url.resourceValues(
                           forKeys: [.contentModificationDateKey]
                       ).contentModificationDate) ?? Date.distantPast
                       
                       return GifFile(
                           modifiedAt: modifiedAt,
                           thumbnail: self.resizedImage(at: url, for: CGSize(width: 200, height: 200)),
                           fileName: url.lastPathComponent,
                           url: url)
                   }).sorted(by: { $0.modifiedAt > $1.modifiedAt })
            
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    
    func resizedImage(at url: URL, for size: CGSize) -> NSImage? {
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

        return NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height))
    }
    
    func onDropStart() {
        contentView.isHidden = true
    }
    
    func onDropEnd() {
        if !isDropping {
            contentView.isHidden = false
        }
    }
    
    func onDrop(path: String) {
        isDropping = true
        startImageRotate()
        
        // Filter
        let filter = "fps=15,scale=800:-1:flags=lanczos"
        
        // Path stuff
        
        let path = URL(fileURLWithPath: path)
        let fileNameAndExtension = path.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let fileExtension = path.pathExtension
        let fileName = fileNameAndExtension.replacingOccurrences(of: ".\(fileExtension)", with: "")
        
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let timestampPath = cachesPath.appendingPathComponent("gifs").appendingPathComponent("\(timestamp)")
        
        try? FileManager.default.createDirectory(at: timestampPath, withIntermediateDirectories: true, attributes: nil)
        
        let pathIn = timestampPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        let pathOut = timestampPath.appendingPathComponent(fileName).appendingPathExtension("gif")
        
        do {
            try FileManager.default.copyItem(at: path, to: pathIn)
            
            toGif(filter: filter, pathIn: pathIn, pathOut: pathOut) { [weak self] in
                try? FileManager.default.removeItem(at: pathIn)
                self?.dropView.fileToPaste = pathOut
                
                DispatchQueue.main.async { [weak self] in
                    self?.isDropping = false
                    self?.reloadImages()
                }
            }
        } catch {
            print("Whoops: \(error)")
        }
    }
    
    func startImageRotate() {
        if !isDropping {
            contentView.isHidden = false
            return
        }
        
        crunchLogoImageView.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        
        // Start animation
        if crunchLogoImageView.layer?.animationKeys()?.count == 0 || crunchLogoImageView.layer?.animationKeys() == nil {
            
            CATransaction.begin()
            
            let rotate = CABasicAnimation(keyPath: "transform.rotation")
            rotate.fromValue = 0
            rotate.toValue = CGFloat(-1 * .pi * 2.0)
            rotate.duration = 2
            rotate.repeatCount = 1
            
            let scaleUp = CABasicAnimation(keyPath: "transform.scale")
            scaleUp.fromValue = 1
            scaleUp.toValue = 1.25
            scaleUp.duration = 0.6
            scaleUp.repeatCount = 1
            scaleUp.beginTime = CACurrentMediaTime() + 1.9
            
            let scaleDown = CABasicAnimation(keyPath: "transform.scale")
            scaleDown.fromValue = 1.25
            scaleDown.toValue = 1.0
            scaleDown.duration = 0.6
            scaleDown.repeatCount = 1
            scaleDown.beginTime = CACurrentMediaTime() + 2.5
            
            CATransaction.setCompletionBlock { [weak self] in
                self?.startImageRotate()
            }

            crunchLogoImageView.layer?.add(rotate, forKey: "rotation")
            crunchLogoImageView.layer?.add(scaleUp, forKey: "scaleUp")
            crunchLogoImageView.layer?.add(scaleDown, forKey: "scaleDown")
            CATransaction.commit()
            
            
        }
    }
    
    @IBAction func onClickSettings(sender: NSView) {
        if let event = NSApplication.shared.currentEvent, let menu = sender.menu {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        }
    }
    
    @objc func deleteAllGifs(_ sender: Any?) {
        DispatchQueue.init(label: "background").async { [weak self] in
            let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let gifsPath = cachesPath.appendingPathComponent("gifs")
            try? FileManager.default.removeItem(at: gifsPath)
            
            DispatchQueue.main.async { [weak self] in
                self?.reloadImages()
            }
        }
    }
    
    @objc func quit(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }
}


extension NSView {
    func setAnchorPoint(anchorPoint:CGPoint) {
        if let layer = self.layer {
            var newPoint = NSPoint(x: self.bounds.size.width * anchorPoint.x, y: self.bounds.size.height * anchorPoint.y)
            var oldPoint = NSPoint(x: self.bounds.size.width * layer.anchorPoint.x, y: self.bounds.size.height * layer.anchorPoint.y)

            newPoint = newPoint.applying(layer.affineTransform())
            oldPoint = oldPoint.applying(layer.affineTransform())

            var position = layer.position

            position.x -= oldPoint.x
            position.x += newPoint.x

            position.y -= oldPoint.y
            position.y += newPoint.y


            layer.anchorPoint = anchorPoint
            layer.position = position
        }
    }
}

extension DashboardViewController : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifFiles.count
    }

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
        
        processMeta = GifTools.createFFMPEGProcess(arguments: argumentsPalette) { [unowned self] (terminated) in
            print("terminated1: \(terminated)")
            
            self.processMeta = GifTools.createFFMPEGProcess(arguments: argumentsWithPalette) { (terminated) in
                print("terminated2: \(terminated)")
                done()
            }
        }
    }
}

extension DashboardViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> DashboardViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("DashboardViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? DashboardViewController else {
            fatalError("Why cant i find DashboardViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
