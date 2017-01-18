//
//  DownloadProgressViewController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/14/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Cocoa

class DownloadProgressViewController: NSViewController, DownloadDelegate, ProcessEndedDelegate {
    
    
    
    @IBOutlet weak var downloadProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var playlistCountProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var timeLeftLabel: NSTextField!
    @IBOutlet weak var videoCountLabel: NSTextField!
    @IBOutlet weak var downloadSpeedLabel: NSTextField!
    
    let downloadController = DownloadController.shared
    
    var downloadProgressIndicatorIsAnimating = false
    var playlistCountProgressIndicatorIsAnimating = false
    var applicationIsDownloadingVideo = false
    
    var currentVideo = 1
    var numberOfVideosInPlaylist = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidBegin), name: processDidBeginNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        
        downloadController.downloadDelegate = self
        
        downloadSpeedLabel.stringValue = "0KiB/s"
        downloadSpeedLabel.isHidden = true
        
        videoCountLabel.stringValue = "No video downloading"
        timeLeftLabel.stringValue = "Add a video above"
        downloadProgressIndicator.doubleValue = 0.0
        playlistCountProgressIndicator.doubleValue = 0.0
        
    }
    
    func processDidBegin() {
        videoCountLabel.stringValue = "Video 1 of 1"
        timeLeftLabel.stringValue = "Getting video..."
        playlistCountProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.startAnimation(self)
        downloadSpeedLabel.isHidden = false
        applicationIsDownloadingVideo = true
    }
    
    func updateProgressBarWith(percentString: String?) {
        let numbersOnly = percentString?.trimmingCharacters(in: NSCharacterSet.decimalDigits.inverted)
        
        guard let numbersOnlyUnwrapped = numbersOnly, let progressPercentage = Double(numbersOnlyUnwrapped) else { return }
        downloadProgressIndicator.doubleValue = Double(progressPercentage)
        if progressPercentage == 100.0 && (currentVideo + 1) <= numberOfVideosInPlaylist {
            currentVideo += 1
            videoCountLabel.stringValue = "Video \(currentVideo) of \(numberOfVideosInPlaylist)"
            playlistCountProgressIndicator.doubleValue = Double(currentVideo) / Double(numberOfVideosInPlaylist)
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
                    secondNumb.characters.removeLast()
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
        
        if (timeLeftString.contains("00:")) { timeLeftString.characters.removeFirst() }
        
        timeLeftLabel.stringValue = "Time remaining: \(timeLeft)"
    }
    
    func userHasAlreadyDownloadedVideo() {
        
        timeLeftLabel.stringValue = "Video already downloaded"
        
        let alert: NSAlert = NSAlert()
        alert.messageText =  "You have already downloaded this video."
        alert.informativeText =  "Please check your output directory."
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        guard let window = self.view.window else { return }
        alert.beginSheetModal(for: window, completionHandler: nil)
        
    }
    
    func processDidEnd() {
        
        downloadProgressIndicatorIsAnimating = false
        
        guard timeLeftLabel.stringValue != "Video already downloaded"  else { return }
        
        playlistCountProgressIndicator.doubleValue = 100
        if downloadController.userDidCancelDownload {
            timeLeftLabel.stringValue = "Download canceled"
        } else if downloadProgressIndicator.doubleValue != 100.0 {
            timeLeftLabel.stringValue = "Error downloading video"
        } else {
            playlistCountProgressIndicator.doubleValue = 100
            timeLeftLabel.stringValue = "Download Complete"
        }
        
        downloadSpeedLabel.stringValue = "0KiB/s"
        downloadSpeedLabel.isHidden = true
        applicationIsDownloadingVideo = false
    }
    
    @IBAction func quitButtonClicked(_ sender: Any) {
        if applicationIsDownloadingVideo {
            let alert: NSAlert = NSAlert()
            alert.messageText =  "You are currently downloading a video."
            alert.informativeText =  "Do you stil want to quit GYI?"
            alert.alertStyle = NSAlertStyle.informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            guard let window = self.view.window else { return }
            alert.beginSheetModal(for: window, completionHandler: { (response) in
                if response == NSAlertFirstButtonReturn { NSApplication.shared().terminate(self) }
            })
        } else {
            NSApplication.shared().terminate(self)
        }
    }
}
