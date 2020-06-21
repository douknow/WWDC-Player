//
//  VideoServices.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/21.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import Foundation
import CoreData

class VideoService {

    let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func likedVideos() -> Group {
        var videos: [Video] = []
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.predicate = NSPredicate(format: "%K=%@", argumentArray: [#keyPath(Video.liked), 1])
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Video.likeDate), ascending: false)]
        do {
            videos = try coreDataStack.context.fetch(request)
        } catch {
            print(error.localizedDescription)
        }
        return Group(title: "Liked", videos: videos)
    }

}
