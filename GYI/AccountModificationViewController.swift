//
//  AccountModificationViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/17/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class AccountModificationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, AccountCreationDelegate, NSAlertDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    private enum CellIdentifiers: String {
        case accountNameCell = "accountNameCell"
        case usernameCell = "usernameCell"
    }
    
    weak var delegate: AccountDeletionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @IBAction func addAccountButtonClicked(_ sender: NSButton) {
        showAddAccountSheet()
    }
    @IBAction func removeAccountButtonClicked(_ sender: NSButton) {
        let selectedRow = tableView.selectedRow
        if tableView.numberOfSelectedRows >= 0 {
            
            let alert: NSAlert = NSAlert()
            alert.messageText =  "Are you sure you want to delete this account?"
            alert.informativeText =  "This account's information cannot be recovered."
            alert.alertStyle = NSAlertStyle.informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.delegate = self
            
            guard let window = self.view.window else { return }
            alert.beginSheetModal(for: window, completionHandler: { (response) in
                if response == NSAlertFirstButtonReturn {
                    
                    let indexSet = IndexSet(arrayLiteral: selectedRow)
                    self.tableView.removeRows(at: indexSet, withAnimation: .slideRight)
                    
                    let account = AccountController.accounts[selectedRow]
                    
                    AccountController.remove(account: account)
                }
            })
            
        }
        
    }

    func newAccountWasCreated() {
        self.tableView.reloadData()
    }
    
    func showAddAccountSheet() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        guard let newAccountWC = storyboard.instantiateController(withIdentifier: "AddNewAccountWindow") as? NSWindowController, let newAccountVC = newAccountWC.window?.contentViewController as? CreateAccountViewController else { return }
        
        newAccountVC.delegate = self
        
        self.view.window?.beginSheet(newAccountWC.window!, completionHandler: { (response) in
            
        })
    }
    
    @IBAction func doneButtonClicked(_ sender: NSButton) {
        dismissSheet()
    }
    
    override func cancelOperation(_ sender: Any?) {
        dismissSheet()
    }
    
    func dismissSheet() {
        self.view.window?.sheetParent?.endSheet(self.view.window!)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return AccountController.accounts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let account = AccountController.accounts[row]
        
        if tableColumn == tableView.tableColumns[0] {
            
            guard let cell = tableView.make(withIdentifier: CellIdentifiers.accountNameCell.rawValue, owner: nil) as? NSTableCellView, let title = account.title else { return nil }
            cell.textField?.stringValue = title
            return cell
            
        } else if tableColumn == tableView.tableColumns[1] {
            guard let cell = tableView.make(withIdentifier: CellIdentifiers.usernameCell.rawValue, owner: nil) as? NSTableCellView, let username = account.username else { return nil }
            cell.textField?.stringValue = username
            return cell
        } else {
            return nil
        }
    }
}
