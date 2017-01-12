//
//  PopoverDownloadProgressViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/12/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class PopoverDownloadProgressViewController: DownloadProgressViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidBegin), name: processDidBeginNotification, object: nil)
        
        downloadController.downloadDelegate = self
        downloadController.processEndedDelegate = self
        
        
        downloadSpeedLabel.stringValue = "0KiB/s"
    }
    
    override func processDidBegin() {
        timeLeftLabel.stringValue = "Getting video..."
        videoCountLabel.stringValue = "Video 1 of 1"
        playlistCountProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.doubleValue = 0.0
        downloadProgressIndicator.startAnimation(self)
    }
    
    override func updateTextViewWith(newLine: String) { }
    
    
}
