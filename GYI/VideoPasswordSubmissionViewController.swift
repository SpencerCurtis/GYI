//
//  VideoPasswordSubmissionViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 3/3/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class VideoPasswordSubmissionViewController: NSViewController {
    
    @IBOutlet weak var videoPasswordTextField: NSSecureTextField!
    
    weak var delegate: VideoPasswordSubmissionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func submitPasswordButtonClicked(_ sender: Any) {
        let videoPassword = videoPasswordTextField.stringValue
        
        delegate?.beginDownloadOfVideoWith(additionalArguments: ["--video-password", videoPassword])
        dismissSheet()
    }
    @IBAction func cancelButtonClicked(_ sender: Any) {
        dismissSheet()
    }
    
    override func cancelOperation(_ sender: Any?) {
        dismissSheet()
    }
    
    func dismissSheet() {
        self.view.window?.sheetParent?.endSheet(self.view.window!)
    }
}

protocol VideoPasswordSubmissionDelegate: class {
    func beginDownloadOfVideoWith(additionalArguments: [String])
}
