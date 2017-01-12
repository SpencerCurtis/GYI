//
//  ViewController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/9/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Cocoa
import Foundation

class MainViewController: NSViewController, AccountCreationDelegate, ProcessEndedDelegate {
    
    @IBOutlet weak var inputTextField: NSTextField!
    @IBOutlet weak var outputPathControl: NSPathControl!
    @IBOutlet weak var accountSelectionPopUpButton: NSPopUpButtonCell!
    @IBOutlet weak var downloadProgressContainerView: NSView!
    
    let downloadController = DownloadController.shared
    
    var containerViewOriginalHeight: CGFloat = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outputPathControl.doubleAction = #selector(openOutputFolderPanel)
        
    }
    
    override func viewWillAppear() {
        
        setupAccountSelectionPopUpButton()
        if let downloadProgressContainerView = downloadProgressContainerView {
            containerViewOriginalHeight = downloadProgressContainerView.frame.height
            downloadProgressContainerView.isHidden = true
            guard let window = self.view.window else { return }
            window.setContentSize(NSSize(width: 600, height: 120))
            
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func processDidEnd() {
        downloadProgressContainerView.isHidden = true
    }
    
    @IBAction func submitButtonTapped(_ sender: NSButton) {
        
        guard inputTextField.stringValue != "" else { return }
        NotificationCenter.default.post(name: processDidBeginNotification, object: self)
        let url = inputTextField.stringValue
        guard let outputFolder = outputPathControl.url?.absoluteString else { return }
        
        let outputWithoutPrefix = outputFolder.replacingOccurrences(of: "file://", with: "")
        
        let output = outputWithoutPrefix + "%(title)s.%(ext)s"
        
        guard let selectedAccountItem = accountSelectionPopUpButton.selectedItem else { return }
        
        let account = AccountController.accounts.filter({$0.title == selectedAccountItem.title}).first
        
        downloadController.downloadVideoAt(videoURL: url, outputFolder: output, account: account)
        
        guard let window = self.view.window, downloadProgressContainerView.isHidden == true else { return }
        downloadProgressContainerView.isHidden = false
        window.change(height: containerViewOriginalHeight)
        
    }
    
    
    @IBAction func AddNewAccountButtonTapped(_ sender: NSMenuItem) {
        addNewAccountSheet()
    }
    
    @IBAction func chooseOutputFolderButtonTapped(_ sender: NSButton) {
        openOutputFolderPanel()
        
    }
    
    
    
    func newAccountWasCreated() {
        setupAccountSelectionPopUpButton()
    }
    
    func addNewAccountSheet() {
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let newAccountWC = storyboard.instantiateController(withIdentifier: "AddNewAccountWindow") as? NSWindowController, let newAccountVC = newAccountWC.window?.contentViewController as? CreateAccountViewController else { return }
        
        newAccountVC.delegate = self
        
        self.view.window?.beginSheet(newAccountWC.window!, completionHandler: { (response) in
            print(response)
        })
        
    }
    
    func setupAccountSelectionPopUpButton() {
        
        
        for account in AccountController.accounts.reversed() {
            guard let title = account.title else { return }
            accountSelectionPopUpButton.insertItem(withTitle: title, at: 0)
        }
    }
    
    func openOutputFolderPanel() {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.begin { (result) in
            if result == NSFileHandlingPanelOKButton {
                guard let path = openPanel.url else { print("No path selected"); return }
                self.outputPathControl.url = path
                print(path)
            }
        }
    }
}


extension NSWindow {
    
    func change(height: CGFloat) {
        var frame = self.frame
        
        frame.size.height += height
        frame.origin.y -= height
        
        self.setFrame(frame, display: true)
    }
}

var processDidBeginNotification = Notification.Name("processDidBegin")
