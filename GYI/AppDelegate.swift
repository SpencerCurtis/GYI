//
//  AppDelegate.swift
//  GYI
//
//  Created by Spencer Curtis on 12/15/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    let popover = NSPopover()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard let button = statusItem.button else { return }
        button.image = NSImage(named: "StatusBarButtonImage")
        button.action = #selector(togglePopover)
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let menuPopoverViewController = storyboard.instantiateController(withIdentifier: "MenuPopoverViewController") as? MenuPopoverViewController else { return }
        
        popover.contentViewController = menuPopoverViewController
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func togglePopover(sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
        
    }
    
    func showPopover(sender: Any?) {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
}

