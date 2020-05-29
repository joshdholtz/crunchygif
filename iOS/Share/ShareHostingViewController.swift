//
//  ShareHostingViewController.swift
//  Share
//
//  Created by Josh Holtz on 5/25/20.
//  Copyright © 2020 Josh Holtz. All rights reserved.
//

import UIKit
import SwiftUI
import MobileCoreServices

@objc(ShareHostingViewController)
class ShareHostingViewController: UIHostingController<ShareContentView> {
    var loadedOnce = false
    let shareContentView = ShareContentView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: shareContentView)
        print("in coder init")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(rootView: shareContentView)
        print("in nib init")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("in super view will appear")
        if !loadedOnce {
            NotificationCenter.default.post(name: Notification.Name.ShareExtensionLoaded, object: extensionContext)
        }
    }
}

struct ShareContentView: View {
    @State var preparedURLsLoading: Bool = false
    @State var preparedURLs: [URL] = []
    @State var extensionContext: NSExtensionContext? = nil
    
    var body: some View {
        PrepareConvertView(loading: self.$preparedURLsLoading, urls: self.$preparedURLs) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.ShareExtensionLoaded)) { info in
                if let extensionContext = info.object as? NSExtensionContext {
                    self.loadVideos(extensionContext: extensionContext)
                }
        }
    }
    
    private func loadVideos(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        
        let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let itemProviders = extensionItems.compactMap({$0.attachments}).flatMap({$0})
        
        let numberOfItems = itemProviders.count
        var numberOfLoadedItems = 0
        
        if numberOfItems > 0 {
            self.preparedURLsLoading = true
        }
        
        for item in itemProviders {
            print("1")
            item.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { (url, error) in
                print("2")
                if let url = url {
                    print("3")
                    do {
                        print("4")
                        let uuid = UUID().uuidString
                        
                        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid)").appendingPathExtension(url.pathExtension)
                        try FileManager.default.moveItem(at: url, to: tempUrl)
                        
                        DispatchQueue.main.async {
                            print("5: \(tempUrl)")
                            self.preparedURLs = self.preparedURLs + [tempUrl]
                            numberOfLoadedItems = numberOfLoadedItems + 1
                            self.preparedURLsLoading = (numberOfItems != numberOfLoadedItems)
                            
                            print("preparedURLs: \(self.preparedURLs)")
                        }
                    } catch {
                        print("ERROR: \(error)")
                        DispatchQueue.main.async {
                            numberOfLoadedItems = numberOfLoadedItems + 1
                            self.preparedURLsLoading = (numberOfItems != numberOfLoadedItems)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        numberOfLoadedItems = numberOfLoadedItems + 1
                        self.preparedURLsLoading = (numberOfItems != numberOfLoadedItems)
                    }
                }
            }
        }
    }
}
