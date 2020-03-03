//
//  CoreDataStack.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Main")
        container.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError()
            }
        }
        return container
    }()
    
    lazy var context: NSManagedObjectContext = {
        return container.viewContext
    }()
    
    // MARK: - Helper Methods
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Could not save data to core data: \(error)")
        }
    }
    
}
