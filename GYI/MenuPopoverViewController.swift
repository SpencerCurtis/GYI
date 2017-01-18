
//  MenuPopoverViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/12/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class MenuPopoverViewController: NSViewController, AccountCreationDelegate, AccountDeletionDelegate {
    
    @IBOutlet weak var inputTextField: NSTextField!
    @IBOutlet weak var outputPathControl: NSPathControl!
    @IBOutlet weak var accountSelectionPopUpButton: NSPopUpButtonCell!
    @IBOutlet weak var downloadProgressContainerView: NSView!
    @IBOutlet weak var submitButton: NSButton!
    
    let downloadController = DownloadController.shared
    var appearance: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = CGColor.white
        
        guard let window = self.view.window else { return }
        
        window.contentMaxSize = NSSize(width: 350, height: self.view.frame.height)
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        outputPathControl.doubleAction = #selector(openOutputFolderPanel)
        
        
    }
    
    override func viewWillAppear() {
        
        setupAccountSelectionPopUpButton()
        
        appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        setupAccountSelectionPopUpButton()
        
        changeAppearanceForMenuStyle()
    }
    
    func processDidEnd() {
        submitButton.title = "Submit"
    }
    
    
    @IBAction func submitButtonTapped(_ sender: NSButton) {
        
        guard inputTextField.stringValue != "" else { return }
        
        if downloadController.applicationIsDownloading {
            downloadController.terminateCurrentTask()
            submitButton.title = "Submit"
            downloadController.userDidCancelDownload = true
            
        } else {
            
            submitButton.title = "Stop Download"
            
            downloadController.applicationIsDownloading = true
            NotificationCenter.default.post(name: processDidBeginNotification, object: self)
            let url = inputTextField.stringValue
            guard let outputFolder = outputPathControl.url?.absoluteString else { return }
            
            let outputWithoutPrefix = outputFolder.replacingOccurrences(of: "file://", with: "")
            
            let output = outputWithoutPrefix + "%(title)s.%(ext)s"
            
            guard let selectedAccountItem = accountSelectionPopUpButton.selectedItem else { return }
            
            let account = AccountController.accounts.filter({$0.title == selectedAccountItem.title}).first
            
            downloadController.downloadVideoAt(videoURL: url, outputFolder: output, account: account)
        }
        
    }
    
    
    @IBAction func addNewAccountButtonTapped(_ sender: NSMenuItem) {
        addNewAccountSheet()
    }
    
    @IBAction func removeAnAccountButtonClicked(_ sender: NSMenuItem) {
        removeAnAccountSheet()
    }
    
    @IBAction func chooseOutputFolderButtonTapped(_ sender: NSButton) {
        openOutputFolderPanel()
        
    }

    func newAccountWasCreated() {
        setupAccountSelectionPopUpButton()
    }
    
    func accountWasDeleted() {
        setupAccountSelectionPopUpButton()
    }
    
    func addNewAccountSheet() {
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let newAccountWC = storyboard.instantiateController(withIdentifier: "AddNewAccountWindow") as? NSWindowController, let newAccountVC = newAccountWC.window?.contentViewController as? CreateAccountViewController else { return }
        
        newAccountVC.delegate = self
        
        self.view.window?.beginSheet(newAccountWC.window!, completionHandler: { (response) in
            
        })
        
    }
    

    func removeAnAccountSheet() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let accountModificationWC = storyboard.instantiateController(withIdentifier: "AccountModificationWC") as? NSWindowController, let accountModificationVC = accountModificationWC.window?.contentViewController as? AccountModificationViewController else { return }
        
        accountModificationVC.delegate = self
        
        self.view.window?.beginSheet(accountModificationWC.window!, completionHandler: { (response) in
            
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
                if self.appearance == "Dark" {
                    self.outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.white})
                }
            }
        }
    }
    
    func changeAppearanceForMenuStyle() {
        if appearance == "Dark" {
            outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.white})
            inputTextField.focusRingType = .none
            inputTextField.backgroundColor = .clear
        } else {
            outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.black})
            inputTextField.focusRingType = .default
            inputTextField.backgroundColor = .black

        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        NotificationCenter.default.post(name: closePopoverNotification, object: self)
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
var processDidEndNotification = Notification.Name("processDidEnd")
