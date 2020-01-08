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
        
        NotificationCenter.default.addObserver(forName: MovDocument.newMovDocument, object: nil, queue: nil) { [weak self] (notification) in
            guard let path = notification.object as? URL else {
                return
            }
            
            self?.showPopover(sender: nil)
            self?.dashboardViewController.onDropStartDefaults()
            self?.dashboardViewController.onDropDefaults(paths: [path]) {
                // Delete folder of mov
                try? FileManager.default.removeItem(at: path.deletingLastPathComponent())
            }
        }
        
        showPopover(sender: nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover(sender: nil)
        return true
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        closePopover(sender: nil)
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
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
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
        let paths = DragTools.getFilePaths(draggingInfo: sender).map { (path) -> URL in
            return URL(fileURLWithPath: path)
        }
        guard !paths.isEmpty else {
            return false
        }

        showPopover(sender: nil)
        dashboardViewController.onDropStartDefaults()
        dashboardViewController.onDropDefaults(paths: paths)

        return true
    }
}
