//
//  ShareViewController.swift
//  Share
//
//  Created by Josh Holtz on 5/22/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import UIKit

import AVFoundation
import MobileCoreServices

private let gifQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "GIF queue"
    queue.maxConcurrentOperationCount = 1
    return queue
}()

class ShareViewController: UIViewController {
    
    lazy var label: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("Do something", for: .normal)
        button.addTarget(self, action: #selector(ShareViewController.doAction), for: .touchUpInside)
        return button
    }()
    
    var videoURLs: [URL] = [] {
        didSet {
//            self.label.text = "URL: \(videoURLs)"
        }
    }
    
    var videoPreviews: [UIImage] = [] {
        didSet {
            self.imageView.image = videoPreviews.first
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // https://stackoverflow.com/questions/17041669/creating-a-blurring-overlay-view/25706250

        // only apply the blur if the user hasn't disabled transparency effects
        if UIAccessibility.isReduceTransparencyEnabled == false {
            view.backgroundColor = .clear

            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            view.insertSubview(blurEffectView, at: 0)
        } else {
            view.backgroundColor = .black
        }
        
        setupView()
        loadVideos()
    }
    
    private func setupView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
    }
    
    private func loadVideos() {
        let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        
        for extensionItem in extensionItems {
            let itemProviders = (extensionItem.attachments ?? [])
            for itemProvider in itemProviders {
                itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { [unowned self] (url, error) in
                    if let url = url {
                        do {
                            let uuid = UUID().uuidString
                            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid)")
                            try FileManager.default.moveItem(at: url, to: tempUrl)
                        
                            itemProvider.loadPreviewImage(options: nil, completionHandler: { [unowned self] (item, error) in
                                if error != nil {
                                    self.label.text = "ERROR with preview"
                                } else if let img = item as? UIImage {
                                    DispatchQueue.main.async {
                                        self.videoURLs = self.videoURLs + [tempUrl]
                                        self.videoPreviews = self.videoPreviews + [img]
                                    }
                                }
                            })
                        } catch {
                            
                        }
                    }
                }
            }
        }
        
//        let items = extensionContext?.inputItems
//        print("items: \(items)")
        
//        items: Optional([<NSExtensionItem: 0x280c48550> - userInfo: {
//            NSExtensionItemAttachmentsKey =     (
//                "<NSItemProvider: 0x282540a80> {types = (\n    \"public.mpeg-4\"\n)}"
//            );
//            "com.apple.UIKit.NSExtensionItemUserInfoIsContentManagedKey" = 0;
//        }])

    }
    
    private func videoSnapshot(url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            self.label.text = "*** Error generating thumbnail: \(error.localizedDescription)"
            return nil
        }
    }
    
    @objc private func doAction () {
        let doneOperation = BlockOperation { [unowned self] in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
        
        self.label.text = "Completed 0 of \(videoURLs.count)"
        
        let filter = "fps=\(10),scale=\(400):\(-1):flags=lanczos"
        let operations = videoURLs.enumerated().map { (index, url) -> [Operation] in
            let operation = GifOperation(path: url, filter: filter)
            let statusOperation = BlockOperation { [unowned self] in
                DispatchQueue.main.async {
                    self.label.text = "Completed \(index+1) of \(self.videoURLs.count)"
                }
            }
            return [operation, statusOperation]
        }.flatMap({$0})
        gifQueue.addOperations(operations + [doneOperation], waitUntilFinished: false)
    }
    
//    @objc private func cancelAction () {
//       let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
//       extensionContext?.cancelRequest(withError: error)
//   }
//
//   @objc private func doneAction() {
//       extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
//   }

}
