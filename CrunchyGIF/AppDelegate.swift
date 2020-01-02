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
        guard let path = DragTools.getFilePath(draggingInfo: sender) else {
            return false
        }

        showPopover(sender: nil)
        dashboardViewController.onDropStart()
        dashboardViewController.onDrop(path: path)

        return true
    }
}
