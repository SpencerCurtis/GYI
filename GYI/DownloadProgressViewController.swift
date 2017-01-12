//
//  DownloadProgressViewController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/14/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Cocoa

class DownloadProgressViewController: NSViewController, DownloadDelegate, ProcessEndedDelegate {
    
    @IBOutlet weak var outputSeparatorLine: NSBox!
    @IBOutlet weak var outputTextViewScrollView: NSScrollView!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet weak var downloadProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var playlistCountProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var timeLeftLabel: NSTextField!
    @IBOutlet weak var videoCountLabel: NSTextField!
    @IBOutlet weak var viewConsoleOutputStackView: NSStackView!
    @IBOutlet weak var consoleOutputDisclosureButton: NSButton!
    @IBOutlet weak var downloadSpeedLabel: NSTextField!
    
    let downloadController = DownloadController.shared
    
    var downloadProgressIndicatorIsAnimating = false
    var playlistCountProgressIndicatorIsAnimating = false
    
    var currentVideo = 1
    var numberOfVideosInPlaylist = 1
    
    var disclosureTriangleIsOpen = false
    
    var originalOutPutTextViewHeight: CGFloat = 256
    var changedOutPutTextViewHeight: CGFloat = 256
    
    var viewIsExpanded = false
    
    var outputTextViewHeight: CGFloat {
        return outputTextView.frame.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidBegin), name: processDidBeginNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)
        
        downloadController.downloadDelegate = self
        downloadController.processEndedDelegate = self
        
        disclosureTriangleIsOpen = true
        
        downloadSpeedLabel.stringValue = "0KiB/s"
        videoCountLabel.stringValue = "No video downloading"
        timeLeftLabel.stringValue = "Add a video above"
        downloadProgressIndicator.doubleValue = 0.0
        playlistCountProgressIndicator.doubleValue = 0.0
        
    }
    
    func processDidBegin() {
        outputTextView.string = ""
        timeLeftLabel.stringValue = "Getting video..."
        playlistCountProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.startAnimation(self)
        showProgressIndicatorsAndTheirLabels()
    }
    
    
    func hideProgressIndicatorsAndTheirLabels() {
        
        
        
        timeLeftLabel.isHidden = true
        videoCountLabel.isHidden = true
        downloadProgressIndicator.isHidden = true
        playlistCountProgressIndicator.isHidden = true
        outputTextView.isHidden = true
        outputSeparatorLine.isHidden = true
        viewConsoleOutputStackView.isHidden = true
        
        guard let window = self.view.window else { return }
        var downloadViewsHiddenFrame = window.frame
        
        downloadViewsHiddenFrame.size.height = 120
        window.setFrame(downloadViewsHiddenFrame, display: true, animate: true)
        
    }
    
    func showProgressIndicatorsAndTheirLabels() {
        
        timeLeftLabel.isHidden = false
        videoCountLabel.isHidden = false
        downloadProgressIndicator.isHidden = false
        playlistCountProgressIndicator.isHidden = false
        outputTextView.isHidden = false
        outputSeparatorLine.isHidden = false
        viewConsoleOutputStackView.isHidden = false
        guard let window = self.view.window, viewIsExpanded == false else { return }
        var downloadViewsShownFrame = window.frame
        
        downloadViewsShownFrame.size.height += 256
        downloadViewsShownFrame.origin.y -= 256
        window.setFrame(downloadViewsShownFrame, display: true, animate: true)
        viewIsExpanded = true
        
    }
    func updateTextViewWith(newLine: String) {
        if !downloadProgressIndicatorIsAnimating { downloadProgressIndicator.startAnimation(self) }
        outputTextView.string?.append("\n\(newLine)")
        
        
        outputTextView.scrollToEndOfDocument(self)
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
            
            //            print(downloadStringWords)
            //
            //            guard let lastString = downloadStringWords.last, let secondNumberIndex = downloadStringWords.index(of: lastString) else { return }
            //            guard let firstNumber = Double(downloadStringWords[secondNumberIndex - 2]) else { return }
            //
            //            if Int(firstNumber) != currentVideo {
            //
            //                currentVideo = Int(firstNumber)
            //
            //                downloadProgressIndicator.doubleValue = firstNumber
            //                downloadProgressIndicator.startAnimation(self)
            //            }
            //
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
        if downloadProgressIndicator.doubleValue != 100.0 {
            timeLeftLabel.stringValue = "Error downloading video"
        } else {
            playlistCountProgressIndicator.doubleValue = 100
            timeLeftLabel.stringValue = "Download Complete"
        }
        
        downloadSpeedLabel.stringValue = "0KiB/s"
    }
    
    @IBAction func viewConsoleOutputButtonTapped(_ sender: NSButton) {
        toggleDisclosureTriangle()
    }
    
    func toggleDisclosureTriangle() {
        if disclosureTriangleIsOpen {
            
            changedOutPutTextViewHeight = outputTextViewHeight
            
            self.view.window?.change(height: -outputTextViewHeight)
            
            outputSeparatorLine.isHidden = true
            outputTextViewScrollView.isHidden = true
            
        } else {
            
            self.view.window?.change(height: changedOutPutTextViewHeight)
            
            outputSeparatorLine.isHidden = false
            outputTextViewScrollView.isHidden = false
        }
        
        disclosureTriangleIsOpen = !disclosureTriangleIsOpen
        
        
    }
}
