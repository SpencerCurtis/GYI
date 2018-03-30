
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
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var videoIsPasswordProtectedCheckboxButtton: NSButton!
    @IBOutlet weak var defaultOutputFolderCheckboxButton: NSButton!
    @IBOutlet weak var downloadProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var playlistCountProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var timeLeftLabel: NSTextField!
    @IBOutlet weak var videoCountLabel: NSTextField!
    @IBOutlet weak var downloadSpeedLabel: NSTextField!
    
    @IBOutlet weak var automaticallyUpdateYoutubeDLCheckboxButton: NSButton!
    
    let downloadController = DownloadController.shared
    
    var downloadProgressIndicatorIsAnimating = false
    var playlistCountProgressIndicatorIsAnimating = false
    var applicationIsDownloadingVideo = false
    
    var currentVideo = 1
    var numberOfVideosInPlaylist = 1
    var videoNeedsAudio = false
    
    
    
    private let defaultOutputFolderKey = "defaultOutputFolder"
    
    var executableUpdatingView: NSView!
    var userDidCancelDownload = false
    
    var appearance: String!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer?.backgroundColor = CGColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentPasswordProtectedVideoAlert), name: downloadController.videoIsPasswordProtectedNotification, object: nil)
        
        downloadController.downloadDelegate = self
        
        downloadSpeedLabel.stringValue = "0KiB/s"
        
        
        videoCountLabel.stringValue = "No video downloading"
        timeLeftLabel.stringValue = "Add a video above"
        downloadProgressIndicator.doubleValue = 0.0
        playlistCountProgressIndicator.doubleValue = 0.0
        
        let userWantsAutoUpdate = UserDefaults.standard.bool(forKey: downloadController.autoUpdateYoutubeDLKey)
        
        automaticallyUpdateYoutubeDLCheckboxButton.state = userWantsAutoUpdate ? .on : .off
        
        
        outputPathControl.doubleAction = #selector(openOutputFolderPanel)
        if let defaultPath = UserDefaults.standard.url(forKey: defaultOutputFolderKey) {
            
            outputPathControl.url = defaultPath
            print(outputPathControl.url!)
        } else {
            outputPathControl.url = URL(string: "file:///Users/\(NSUserName)/Downloads")
        }
        
        
        
        defaultOutputFolderCheckboxButton.state = NSControl.StateValue(rawValue: 1)
        
        guard let popover = downloadController.popover else { return }
        popover.delegate = self
    }
    
    override func viewWillAppear() {
        
        setupAccountSelectionPopUpButton()
    }
    
    @objc func processDidEnd() {
        submitButton.title = "Submit"
        
        if !userDidCancelDownload { inputTextField.stringValue = "" }
        
        downloadProgressIndicatorIsAnimating = false
        
        guard timeLeftLabel.stringValue != "Video already downloaded"  else { return }
        
        playlistCountProgressIndicator.doubleValue = 100.0
        
        if downloadProgressIndicator.doubleValue == 100.0 {
            playlistCountProgressIndicator.doubleValue = 100.0
            timeLeftLabel.stringValue = "Download Complete"
        } else if downloadController.userDidCancelDownload {
            timeLeftLabel.stringValue = "Download canceled"
        } else if downloadProgressIndicator.doubleValue != 100.0 {
            timeLeftLabel.stringValue = "Error downloading video"
        }
        
        downloadSpeedLabel.stringValue = "0KiB/s"
        downloadSpeedLabel.isHidden = true
        applicationIsDownloadingVideo = false
        
        
        downloadProgressIndicator.stopAnimation(self)
        playlistCountProgressIndicator.stopAnimation(self)
    }
    
    func presentVideoPasswordSubmissionSheet() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        guard let accountModificationWC = (storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "VideoPasswordSubmissionWC")) as? NSWindowController), let window = accountModificationWC.window,
            let videoPasswordSubmissionVC = window.contentViewController as? VideoPasswordSubmissionViewController else { return }
        
        videoPasswordSubmissionVC.delegate = self
        
        self.view.window?.beginSheet(window, completionHandler: nil)
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
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        guard let accountModificationWC = (storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "AccountModificationWC")) as? NSWindowController), let window = accountModificationWC.window,
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
        if sender.state.rawValue == 1 {
            let path = outputPathControl.url
            
            UserDefaults.standard.set(path, forKey: defaultOutputFolderKey)
        }
    }
    
    @objc func openOutputFolderPanel() {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.begin { (result) in
            
            guard let path = openPanel.url, result.rawValue == NSFileHandlingPanelOKButton else { return }
            
            if self.outputPathControl.url != path { self.defaultOutputFolderCheckboxButton.state = NSControl.StateValue(rawValue: 0) }
            
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
    
    // MARK: - Password Protected Videos
    
    @objc func presentPasswordProtectedVideoAlert() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        guard let accountModificationWC = (storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "VideoPasswordSubmissionWC")) as? NSWindowController), let window = accountModificationWC.window,
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
    
    func popoverWillShow(_ notification: Notification) {
        appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        changeAppearanceForMenuStyle()
        guard let executableUpdatingView = executableUpdatingView else { return }
        executableUpdatingView.layer?.backgroundColor = appearance == "Dark" ? .white : .black
    }
    
    // MARK: - Other
    
    override func cancelOperation(_ sender: Any?) {
        NotificationCenter.default.post(name: closePopoverNotification, object: self)
    }
    
    @IBAction func quitButtonClicked(_ sender: Any) {
        if applicationIsDownloadingVideo {
            let alert: NSAlert = NSAlert()
            alert.messageText =  "You are currently downloading a video."
            alert.informativeText =  "Do you stil want to quit GYI?"
            alert.alertStyle = NSAlert.Style.informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            guard let window = self.view.window else { return }
            alert.beginSheetModal(for: window, completionHandler: { (response) in
                if response == NSApplication.ModalResponse.alertFirstButtonReturn { NSApplication.shared.terminate(self) }
            })
        } else {
            downloadController.popover?.performClose(nil)
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(terminateApp), userInfo: nil, repeats: false)
        }
        
    }
}

// MARK: - Download Delegate/ General Downloading

extension MenuPopoverViewController: DownloadDelegate {
    
    @IBAction func submitButtonTapped(_ sender: NSButton) {
        
        guard inputTextField.stringValue != "" else { return }
        
        guard videoIsPasswordProtectedCheckboxButtton.state.rawValue == 0 else { presentVideoPasswordSubmissionSheet(); return }
        
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
        self.processDidBegin()
        
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
        
        self.processDidBegin()
        
        guard let outputFolder = outputPathControl.url?.absoluteString else { return }
        
        let outputWithoutPrefix = outputFolder.replacingOccurrences(of: "file://", with: "")
        
        let output = outputWithoutPrefix + "%(title)s.%(ext)s"
        
        guard let selectedAccountItem = accountSelectionPopUpButton.selectedItem else { return }
        
        let account = AccountController.accounts.filter({$0.title == selectedAccountItem.title}).first
        
        downloadController.downloadVideoAt(videoURL: url, outputFolder: output, account: account, additionalArguments: additionalArguments)
        
    }
    
    func processDidBegin() {
        videoCountLabel.stringValue = "Video 1 of 1"
        timeLeftLabel.stringValue = "Getting video..."
        playlistCountProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.isIndeterminate = true
        downloadProgressIndicator.startAnimation(self)
        downloadSpeedLabel.isHidden = false
        applicationIsDownloadingVideo = true
    }
    
    func updateProgressBarWith(percentString: String?) {
        let numbersOnly = percentString?.trimmingCharacters(in: NSCharacterSet.decimalDigits.inverted)
        
        guard let numbersOnlyUnwrapped = numbersOnly, let progressPercentage = Double(numbersOnlyUnwrapped) else { return }
        
        if downloadProgressIndicator.isIndeterminate {
            downloadProgressIndicator.isIndeterminate = false
        }
        
        if progressPercentage > downloadProgressIndicator.doubleValue {
            downloadProgressIndicator.doubleValue = progressPercentage
        }
        
        if progressPercentage == 100.0 && (currentVideo + 1) <= numberOfVideosInPlaylist {
            
            currentVideo += 1
            videoCountLabel.stringValue = "Video \(currentVideo) of \(numberOfVideosInPlaylist)"
            playlistCountProgressIndicator.doubleValue = Double(currentVideo) / Double(numberOfVideosInPlaylist)
        }
        
        if currentVideo == 1 && numberOfVideosInPlaylist == 1 && progressPercentage == 100.0 {
            videoNeedsAudio = true
            if !downloadProgressIndicator.isIndeterminate {
                downloadProgressIndicator.isIndeterminate = true
            }
        }
    }
    
    func updatePlaylistProgressBarWith(downloadString: String) {
        
        if downloadString.contains("Downloading video") {
            
            let downloadStringWords = downloadString.components(separatedBy: " ")
            
            var secondNumber = 1.0
            var secondNumberInt = 1
            if let secondNum = downloadStringWords.last {
                var secondNumb = secondNum
                if secondNumb.contains("\n") {
                    secondNumb.removeLast()
                    guard let secondNum = Double(secondNumb), let secondNumInt = Int(secondNumb) else { return }
                    secondNumber = secondNum
                    secondNumberInt = secondNumInt
                } else {
                    guard let secondNum = Double(secondNumb), let secondNumInt = Int(secondNumb) else { return }
                    secondNumber = secondNum
                    secondNumberInt = secondNumInt
                }
            }
            
            
            playlistCountProgressIndicator.minValue = 0.0
            playlistCountProgressIndicator.maxValue = 1.0
            playlistCountProgressIndicator.startAnimation(self)
            let percentage = Double(currentVideo) / secondNumber
            numberOfVideosInPlaylist = Int(secondNumber)
            
            videoCountLabel.stringValue = "Video \(currentVideo) of \(secondNumberInt)"
            playlistCountProgressIndicator.doubleValue = percentage
            
            
        }
    }
    
    func updateDownloadSpeedLabelWith(downloadString: String) {
        
        let downloadStringWords = downloadString.components(separatedBy: " ")
        
        guard let atStringIndex = downloadStringWords.index(of: "at") else { return }
        
        var speed = downloadStringWords[(atStringIndex + 1)]
        
        if speed == "" { speed = downloadStringWords[(atStringIndex + 2)] }
        
        
        downloadSpeedLabel.stringValue = speed
    }
    
    func parseResponseStringForETA(responseString: String) {
        let words = responseString.components(separatedBy: " ")
        
        guard let timeLeft = words.last else { return }
        
        var timeLeftString = timeLeft
        
        if (timeLeftString.contains("00:")) { timeLeftString.removeFirst() }
        if videoNeedsAudio {
            timeLeftLabel.stringValue = "Getting audio. Almost done."
        } else {
            timeLeftLabel.stringValue = "Getting video. Time remaining: \(timeLeft)"
        }
        //        timeLeftLabel.stringValue = "Time remaining: \(timeLeft)"
    }
    
    func userHasAlreadyDownloadedVideo() {
        
        timeLeftLabel.stringValue = "Video already downloaded"
        
        let alert: NSAlert = NSAlert()
        alert.messageText =  "You have already downloaded this video."
        alert.informativeText =  "Please check your output directory."
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        guard let window = self.view.window else { return }
        alert.beginSheetModal(for: window, completionHandler: nil)
        
    }
    
    @objc func terminateApp() {
        NSApplication.shared.terminate(_:self)
    }
    
    @IBAction func automaticallyUpdateYoutubeDLCheckboxButtonClicked(_ sender: NSButton) {
        switch sender.state {
            
        case .off:
            UserDefaults.standard.set(false, forKey: downloadController.autoUpdateYoutubeDLKey)
        case .on:
            UserDefaults.standard.set(true, forKey: downloadController.autoUpdateYoutubeDLKey)
        default:
            break
        }
    }
}

// MARK: - Resizing (may not be needed)

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
