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
        let request: NSFetchRequest<DownloadData> = DownloadData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        do {
            let downloadDatas = try coreDataStack.context.fetch(request)
            allDownloadItems = downloadDatas.map {
                DownloadItem(video: $0.video!, url: $0.url!, coreDataStack: self.coreDataStack, downloadData: $0)
            }
        } catch {
            print("Could fetch download data from core data: \(error)")
        }
    }
    
}
