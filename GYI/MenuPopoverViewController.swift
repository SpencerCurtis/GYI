
//  MenuPopoverViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/12/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class MenuPopoverViewController: NSViewController, AccountCreationDelegate, AccountDeletionDelegate, ExecutableUpdateDelegate {
    
    @IBOutlet weak var inputTextField: NSTextField!
    @IBOutlet weak var outputPathControl: NSPathControl!
    @IBOutlet weak var accountSelectionPopUpButton: NSPopUpButtonCell!
    @IBOutlet weak var downloadProgressContainerView: NSView!
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var defaultOutputFolderCheckboxButton: NSButton!
    
    private let defaultOutputFolderKey = "defaultOutputFolder"
    
    let downloadController = DownloadController.shared
    var appearance: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = CGColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        outputPathControl.doubleAction = #selector(openOutputFolderPanel)
        if let defaultPath = UserDefaults.standard.url(forKey: defaultOutputFolderKey) {
            
            outputPathControl.url = defaultPath
            print(outputPathControl.url!)
        } else {
            
            outputPathControl.url = URL(string: "file:///Users/\(NSUserName)/Downloads")
        }
        defaultOutputFolderCheckboxButton.state = 1
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
    
    @IBAction func manageAccountsButtonClicked(_ sender: NSMenuItem) {
        manageAccountsSheet()
    }
    
    
    // MARK: - Account Creation/Deletion Delegates
    
    func newAccountWasCreated() {
        setupAccountSelectionPopUpButton()
    }
    
    func accountWasDeletedWith(title: String) {
        accountSelectionPopUpButton.removeItem(withTitle: title)
    }
    
    
    func manageAccountsSheet() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let accountModificationWC = (storyboard.instantiateController(withIdentifier: "AccountModificationWC") as? NSWindowController), let window = accountModificationWC.window,
            let accountModificationVC = window.contentViewController as? AccountModificationViewController else { return }
        
        accountModificationVC.delegate = self
        self.view.window?.beginSheet(window, completionHandler: { (response) in
            self.setupAccountSelectionPopUpButton()
        })
    }
    
    func setupAccountSelectionPopUpButton() {
        
        
        for account in AccountController.accounts.reversed() {
            guard let title = account.title else { return }
            accountSelectionPopUpButton.insertItem(withTitle: title, at: 0)
        }
    }
    
    // MARK: - Output folder selection
    
    @IBAction func chooseOutputFolderButtonTapped(_ sender: NSButton) {
        openOutputFolderPanel()
        
    }
    
    @IBAction func defaultOutputFolderButtonClicked(_ sender: NSButton) {
        if sender.state == 1 {
            let path = outputPathControl.url
            
            UserDefaults.standard.set(path, forKey: defaultOutputFolderKey)
        }
    }
    
    func openOutputFolderPanel() {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.begin { (result) in
            
            guard let path = openPanel.url, result == NSFileHandlingPanelOKButton else { return }
            
            if self.outputPathControl.url != path { self.defaultOutputFolderCheckboxButton.state = 0 }
            
            self.outputPathControl.url = path
            
            if self.appearance == "Dark" {
                self.outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.white})
            }
        }
    }
    
    func executableDidBeginUpdateWith(dataString: String) {
        
    }
    
    func executableDidFinishUpdatingWith(dataString: String) {
        
    }
    
    // MARK: - Appearance
    
    func changeAppearanceForMenuStyle() {
        if appearance == "Dark" {
            outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.white})
            inputTextField.focusRingType = .none
        } else {
            outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.black})
            inputTextField.focusRingType = .default
            inputTextField.backgroundColor = .clear
        }
    }
    
    // MARK: - Other
    
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
