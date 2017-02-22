//
//  AccountController.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/11/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Foundation
import CoreData

class AccountController {
        
    static var accounts: [Account] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        
        let moc = CoreDataStack.context
        
        let results = try? moc.fetch(request)
        
        return results ?? []
        
    }
    
    static func createAccountWith(title: String, username: String, password: String) {
        
        let _ = Account(title: title, username: username, password: password)
        saveToPersistentStore()
    }
    
    static func removeAllAccountsFromPersistence() {
        let moc = CoreDataStack.context
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: Account.fetchRequest())
        do {
            try moc.execute(deleteRequest)
        } catch {
            print("Error deleting all accounts: \(error.localizedDescription)")
        }
    }
    
    static func saveToPersistentStore() {
        let moc = CoreDataStack.context
        
        do {
            try moc.save()
        } catch {
            NSLog("Error saving managed object context: \(error.localizedDescription)")
        }
    }
    
    static func remove(account: Account) {
        let moc = account.managedObjectContext
        
        moc?.delete(account)
        saveToPersistentStore()
        
    }
    
}


protocol AccountCreationDelegate: class {
    func newAccountWasCreated()
}

protocol AccountDeletionDelegate: class {
    func accountWasDeletedWith(title: String)
}
