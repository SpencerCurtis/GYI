//
//  Account + Convenience.swift
//  YoutubeDLGUI
//
//  Created by Spencer Curtis on 12/11/16.
//  Copyright © 2016 Spencer Curtis. All rights reserved.
//

import Foundation
import CoreData

extension Account {
    
    convenience init(title: String, username: String, password: String, context: NSManagedObjectContext = CoreDataStack.context) {
        
        self.init(context: context)
        
        self.title = title
        self.username = username
        self.password = password
    }
    
    static var kTitle: String { return "title" }
    static var kUsername: String { return "username" }
    static var kPassword: String { return "password" }
    
    var dictionaryRepresentation: [String: String] {
        guard let title = title, let username = username, let password = password else { return ["Error": "Could not create dictionary representation of account"] }
        return [Account.kTitle: title, Account.kUsername: username, Account.kPassword: password]
    }
}
