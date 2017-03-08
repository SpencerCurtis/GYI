
//  MenuPopoverViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/12/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class MenuPopoverViewController: NSViewController, NSPopoverDelegate, AccountCreationDelegate, AccountDeletionDelegate, ExecutableUpdateDelegate, VideoPasswordSubmissionDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var inputTextField: NSTextField!
    @IBOutlet weak var outputPathControl: NSPathControl!
    @IBOutlet weak var accountSelectionPopUpButton: NSPopUpButtonCell!
    @IBOutlet weak var downloadProgressContainerView: NSView!
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var defaultOutputFolderCheckboxButton: NSButton!
    
    private let defaultOutputFolderKey = "defaultOutputFolder"
    
    var executableUpdatingView: NSView!
    var userDidCancelDownload = false
    
    let downloadController = DownloadController.shared
    var appearance: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer?.backgroundColor = CGColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentPasswordProtectedVideoAlert)    , name: downloadController.videoIsPasswordProtectedNotification, object: nil)
        
        outputPathControl.doubleAction = #selector(openOutputFolderPanel)
        if let defaultPath = UserDefaults.standard.url(forKey: defaultOutputFolderKey) {
            
            outputPathControl.url = defaultPath
            print(outputPathControl.url!)
        } else {
            outputPathControl.url = URL(string: "file:///Users/\(NSUserName)/Downloads")
        }
        
        defaultOutputFolderCheckboxButton.state = 1
        
        guard let popover = downloadController.popover else { return }
        popover.delegate = self
    }
    
    override func viewWillAppear() {
        
        setupAccountSelectionPopUpButton()
    }
    
    func processDidEnd() {
        submitButton.title = "Submit"
        
        if !userDidCancelDownload { inputTextField.stringValue = "" }
    }
    
    
    @IBAction func submitButtonTapped(_ sender: NSButton) {
        
        guard inputTextField.stringValue != "" else { return }
        
        if downloadController.applicationIsDownloading {
            downloadController.terminateCurrentTask()
            submitButton.title = "Submit"
            downloadController.userDidCancelDownload = true
            
        } else {
            beginDownloadOfVideoWith(url: inputTextField.stringValue)
        }
        
    }
    
    func beginDownloadOfVideoWith(url: String) {
        submitButton.title = "Stop Download"
        
        downloadController.applicationIsDownloading = true
        NotificationCenter.default.post(name: processDidBeginNotification, object: self)
        
        guard let outputFolder = outputPathControl.url?.absoluteString else { return }
        
        let outputWithoutPrefix = outputFolder.replacingOccurrences(of: "file://", with: "")
        
        let output = outputWithoutPrefix + "%(title)s.%(ext)s"
        
        guard let selectedAccountItem = accountSelectionPopUpButton.selectedItem else { return }
        
        let account = AccountController.accounts.filter({$0.title == selectedAccountItem.title}).first
        
        downloadController.downloadVideoAt(videoURL: url, outputFolder: output, account: account)
    }
    
    func beginDownloadOfVideoWith(additionalArguments: [String]) {
        
        let url = inputTextField.stringValue
        
        submitButton.title = "Stop Download"
        
        downloadController.applicationIsDownloading = true
        NotificationCenter.default.post(name: processDidBeginNotification, object: self)
        
        guard let outputFolder = outputPathControl.url?.absoluteString else { return }
        
        let outputWithoutPrefix = outputFolder.replacingOccurrences(of: "file://", with: "")
        
        let output = outputWithoutPrefix + "%(title)s.%(ext)s"
        
        guard let selectedAccountItem = accountSelectionPopUpButton.selectedItem else { return }
        
        let account = AccountController.accounts.filter({$0.title == selectedAccountItem.title}).first
        
        downloadController.downloadVideoAt(videoURL: url, outputFolder: output, account: account, additionalArguments: additionalArguments)

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
    
    // MARK: - ExecutableUpdateDelegate
    
    func executableDidBeginUpdateWith(dataString: String) {
        self.view.addSubview(self.executableUpdatingView, positioned: .above, relativeTo: nil)
    }
    
    func executableDidFinishUpdatingWith(dataString: String) {
        
    }
    
    func setupExecutableUpdatingView() {
        let executableUpdatingView = NSView(frame: self.view.frame)
        executableUpdatingView.wantsLayer = true
        
        executableUpdatingView.layer?.backgroundColor = appearance == "Dark" ? .white : .black
        
        self.executableUpdatingView = executableUpdatingView
        
        // WARNING: - Remove this. This is only for testing.
        self.view.addSubview(self.executableUpdatingView, positioned: .above, relativeTo: nil)
        
    }
    
    func popoverWillShow(_ notification: Notification) {
        appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        changeAppearanceForMenuStyle()
        guard let executableUpdatingView = executableUpdatingView else { return }
        executableUpdatingView.layer?.backgroundColor = appearance == "Dark" ? .white : .black
    }
    
    // MARK: - Password Protected Videos
    
    func presentPasswordProtectedVideoAlert() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let accountModificationWC = (storyboard.instantiateController(withIdentifier: "VideoPasswordSubmissionWC") as? NSWindowController), let window = accountModificationWC.window,
            let videoPasswordSubmissionVC = window.contentViewController as? VideoPasswordSubmissionViewController else { return }
        
        videoPasswordSubmissionVC.delegate = self
        
        self.view.window?.beginSheet(window, completionHandler: { (response) in
            
        })
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
