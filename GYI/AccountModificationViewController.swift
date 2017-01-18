//
//  AccountModificationViewController.swift
//  GYI
//
//  Created by Spencer Curtis on 1/17/17.
//  Copyright © 2017 Spencer Curtis. All rights reserved.
//

import Cocoa

class AccountModificationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
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
    
    @IBAction func removeAccountButtonTapped(_ sender: NSButton) {
        let selectedRow = tableView.selectedRow
        if tableView.numberOfSelectedRows >= 0 {
            
            let indexSet = IndexSet(arrayLiteral: selectedRow)
            tableView.removeRows(at: indexSet, withAnimation: .slideRight)
            
            let account = AccountController.accounts[selectedRow]
            
            AccountController.remove(account: account)
        }
        
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
