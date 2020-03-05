//
//  ContainerService.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/5.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation

class ContainerService {
    
    static let shared = ContainerService()
    
    let coreDataStack = CoreDataStack()
    
    lazy var shareStore: ShareStore = {
         ShareStore(coreDataStack: coreDataStack)
    }()
    
    private init() { }
    
}
