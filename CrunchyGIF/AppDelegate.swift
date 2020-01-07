//
//  AppDelegate.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 10/21/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    
    let dashboardViewController = DashboardViewController.freshController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = dashboardViewController
        
        statusItem.button?.window?.registerForDraggedTypes([.fileURL])
        statusItem.button?.window?.delegate = self
        
        
        
        NotificationCenter.default.addObserver(forName: MovDocument.newMovDocument, object: nil, queue: nil) { (notification) in
            guard let document = notification.object as? MovDocument else {
                return
            }
            
            print("document: \(document)")
            document.close()
            NSDocumentController.shared.removeDocument(document)
            
            print("current document: \(NSDocumentController.shared.currentDocument)")
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // https://stackoverflow.com/a/11609984/2464643
        print("hey: \(urls)")
        
        let paths = urls.map { (url) -> String in
            return url.absoluteString
        }
        
        var fileSize : UInt64

        do {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: paths.first!)
            fileSize = attr[FileAttributeKey.size] as! UInt64

            //if you convert to NSDictionary, you can get file size old way as well.
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
            print("file size: \(fileSize)")
        } catch {
            print("Error: \(error)")
        }
        
//        showPopover(sender: nil)
//        dashboardViewController.onDropStartDefaults()
//        dashboardViewController.onDropDefaults(paths: paths)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
}

extension AppDelegate: NSWindowDelegate, NSDraggingDestination {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragTools.checkExtension(sender) {
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let paths = DragTools.getFilePaths(draggingInfo: sender)
        guard !paths.isEmpty else {
            return false
        }

        showPopover(sender: nil)
        dashboardViewController.onDropStartDefaults()
        dashboardViewController.onDropDefaults(paths: paths)

        return true
    }
}
