//
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
        appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        changeAppearanceForMenuStyle()

    }
    
    func changeAppearanceForMenuStyle() {
        if appearance == "Dark" {
            outputPathControl.pathComponentCells().forEach({ (cell) in
                cell.textColor = NSColor.white
                inputTextField.focusRingType = .none
            })
        }
    }
}
