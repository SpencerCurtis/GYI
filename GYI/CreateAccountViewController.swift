//
//  CreateAccountViewController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/11/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Cocoa

class CreateAccountViewController: NSViewController {
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!
    
    weak var delegate: AccountCreationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func addAccountButtonTapped(_ sender: NSButton) {
        
        let title = nameTextField.stringValue
        let username = usernameTextField.stringValue
        let password = passwordTextField.stringValue
        guard title != "", username != "", password != "" else {  /* Present error alert here */ return }
        
        AccountController.createAccountWith(title: title, username: username, password: password)
        delegate?.newAccountWasCreated()
        
        self.view.window?.sheetParent?.endSheet(self.view.window!)
    }
    
    @IBAction func cancelButtonTapped(_ sender: NSButton) {
        self.view.window?.sheetParent?.endSheet(self.view.window!)
    }
}
