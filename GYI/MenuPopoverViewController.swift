
//  MenuPopoverViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/12/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class MenuPopoverViewController: MainViewController {

    var appearance: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = CGColor.white
        
        guard let window = self.view.window else { return }
        
        window.contentMaxSize = NSSize(width: 350, height: self.view.frame.height)
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDidEnd), name: processDidEndNotification, object: nil)

    }
    
    override func viewWillAppear() {
        
        appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        setupAccountSelectionPopUpButton()
        
        changeAppearanceForMenuStyle()
    }
    
    func changeAppearanceForMenuStyle() {
        if appearance == "Dark" {
            outputPathControl.pathComponentCells().forEach({$0.textColor = NSColor.white})
            inputTextField.focusRingType = .none
        }
    }
}
