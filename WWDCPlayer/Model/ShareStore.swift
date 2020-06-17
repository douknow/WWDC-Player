//
//  ShareStore.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/5.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import Combine
import CoreData

class ShareStore {
    
    @Published private(set) var allDownloadItems: [DownloadItem] = []
    
    let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        
        restoreDownloadList()
    }
    
    func insert(downloadItem: DownloadItem) {
        allDownloadItems = [downloadItem] + allDownloadItems
    }
    
    func remove(downloadItem: DownloadItem) {
        allDownloadItems = allDownloadItems.filter { $0 !== downloadItem }
    }
    
    func restoreDownloadList() {
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.predicate = NSPredicate(format: "%@ != nil", argumentArray: [#keyPath(Video.downloadData)])
        let videos = (try? coreDataStack.context.fetch(request)) ?? []
        allDownloadItems = DownloadItem.parse(from: videos, coreDataStack: coreDataStack)
    }
    
}
