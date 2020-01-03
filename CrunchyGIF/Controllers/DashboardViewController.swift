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
    @IBOutlet var dropViewTop: DropView!
    @IBOutlet var dropViewBottom: DropView!
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var settingsView: NSView!
    
    @IBOutlet weak var defaultsDescription: NSTextField!
    
    private var progressViewController: ProgressViewController!
    private var settingsViewController: SettingsViewController!
    
    @IBOutlet var settingsButton: NSButton!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var isDropping = false
    
    var gifFiles: [GifFile] = []
    var processMeta: (Process, DispatchWorkItem)?
    
    enum State {
        case gifs, dropDefaults, dropCustom, settings, progress
    }
    
    var state: State = .gifs {
        didSet {
            switch state {
            case .gifs:
                contentView.isHidden = false
                settingsView.isHidden = true
                progressView.isHidden = true
                
                dropViewTop.isHidden = false
                dropViewBottom.isHidden = false
            case .dropDefaults:
                contentView.isHidden = true
                settingsView.isHidden = true
                progressView.isHidden = true
                
                dropViewTop.isHidden = false
                dropViewBottom.isHidden = false
                
                dropViewTop.layer?.borderColor = NSColor.white.cgColor
                dropViewTop.layer?.borderWidth = 0
                dropViewBottom.layer?.borderColor = NSColor.white.cgColor
                dropViewBottom.layer?.borderWidth = 1
                
                dropViewTop.alphaValue = 0.5
                dropViewBottom.alphaValue = 1
            case .dropCustom:
                contentView.isHidden = true
                settingsView.isHidden = true
                progressView.isHidden = true
                
                dropViewTop.isHidden = false
                dropViewBottom.isHidden = false
                
                dropViewTop.layer?.borderColor = NSColor.white.cgColor
                dropViewTop.layer?.borderWidth = 1
                dropViewBottom.layer?.borderColor = NSColor.white.cgColor
                dropViewBottom.layer?.borderWidth = 0
                
                dropViewTop.alphaValue = 1
                dropViewBottom.alphaValue = 0.5
            case .settings:
                contentView.isHidden = true
                settingsView.isHidden = false
                progressView.isHidden = true
                
                dropViewTop.isHidden = true
                dropViewBottom.isHidden = true
            case .progress:
                contentView.isHidden = true
                settingsView.isHidden = true
                progressView.isHidden = false
                
                dropViewTop.isHidden = true
                dropViewBottom.isHidden = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        state = .gifs
        
        configureCollectionView()
        
        settingsButton.appearance = NSAppearance.current
        settingsButton.contentTintColor = NSColor.lightGray
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(settings(_:)), keyEquivalent: "S"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Delete All Gifs", action: #selector(deleteAllGifs(_:)), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Donate", action: #selector(donate(_:)), keyEquivalent: "D"))
        menu.addItem(NSMenuItem(title: "Contact", action: #selector(contact(_:)), keyEquivalent: "C"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "Q"))
        settingsButton.menu = menu
        
        navigationBar.wantsLayer = true
        navigationBar.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        dropViewTop.wantsLayer = true
        dropViewTop.layer?.backgroundColor = NSColor.clear.cgColor
        dropViewBottom.wantsLayer = true
        dropViewBottom.layer?.backgroundColor = NSColor.clear.cgColor
        
        dropViewTop.onStart = onDropStartCustom
        dropViewTop.onEnd = onDropEnd
        dropViewTop.onDrop = onDropCustom
        
        dropViewBottom.onStart = onDropStartDefaults
        dropViewBottom.onEnd = onDropEnd
        dropViewBottom.onDrop = onDropDefaults
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        reloadImages()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ProgressViewController":
            progressViewController = segue.destinationController as? ProgressViewController
        case "SettingsViewController":
            settingsViewController = segue.destinationController as? SettingsViewController
        default:
            break
        }
    }
    
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
        
        view.wantsLayer = true
        
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
    
    func onDropStartDefaults() {
        let setting = Setting.fetch(kind: .defaults)
        
        var parts = ["\(setting.fps) FPS"]
        if setting.width > 0 {
            parts.append("\(setting.width) width")
        }
        if setting.height > 0 {
            parts.append("\(setting.height) height")
        }
        
        let text = "Using \(parts.joined(separator: ", ")) from Settings"
        defaultsDescription.stringValue = text
        
        state = .dropDefaults
    }
    
    func onDropStartCustom() {
        state = .dropCustom
    }
    
    func onDropEnd() {
        if !isDropping {
            state = .gifs
        }
    }
    
    func onDropDefaults(path: String) {
        let setting = Setting.fetch(kind: .defaults)
        onDrop(path: path, setting: setting)
    }
    
    func onDropCustom(path: String) {
        settingsViewController.loadSetting(kind: .custom)
        settingsViewController.onBack = { [unowned self] in
            self.state = .gifs
        }
        settingsViewController.onDone = { [unowned self] in
            let setting = Setting.fetch(kind: .custom)
            self.onDrop(path: path, setting: setting)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.state = .settings
        }
    }
    
    func onDrop(path: String, setting: Setting) {
        state = .progress
        
        isDropping = true
        startImageRotate()
        
        // Filter
        let filter = "fps=\(setting.fps),scale=\(setting.width):\(setting.height):flags=lanczos"
        
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
                self?.dropViewBottom.fileToPaste = pathOut
                
                DispatchQueue.main.async { [weak self] in
                    self?.isDropping = false
                    self?.progressViewController.stop()
                    self?.reloadImages()
                }
            }
        } catch {
            print("Whoops: \(error)")
        }
    }
    
    func startImageRotate() {
        progressViewController.start { [unowned self] in
            self.state = .gifs
        }
    }
    
    @IBAction func onClickSettings(sender: NSView) {
        if let event = NSApplication.shared.currentEvent, let menu = sender.menu {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        }
    }
    
    @objc func settings(_ sender: Any?) {
        settingsViewController.loadSetting(kind: .defaults)
        settingsViewController.onBack = { [unowned self] in
            self.state = .gifs
        }
        settingsViewController.onDone = { [unowned self] in
            self.state = .gifs
        }
        
        state = .settings
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
    
    @objc func donate(_ sender: Any?) {
        NSWorkspace.shared.open(Constants.donateURL)
    }
    
    @objc func contact(_ sender: Any?) {
        NSWorkspace.shared.open(Constants.contactEmailURL)
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
