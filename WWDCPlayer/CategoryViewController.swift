//
//  HomeViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewController: UITableViewController {

    var coreDataStack: CoreDataStack!

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
        tableView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.item) {
        case (0, 0):
            // show collection
            showCollection()
        case (0, 1):
            // show topic
            showTopic()
        case (0, 2):
            // show all video
            showAllVideo()
        case (1, 0):
            showLikedVideo()
        case (1, 1):
            showDownlaoded()
        default:
            break
        }
    }

    func showCollection() {

    }

    func showTopic() {

    }

    func showAllVideo() {
        let vc = storyboard!.instantiateViewController(identifier: "AllVideo") as! HomeViewController
        vc.coreDataStack = coreDataStack
        navigationController?.pushViewController(vc, animated: true)
    }

    func showLikedVideo() {
        var videos: [Video] = []
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.predicate = NSPredicate(format: "%K=%@", argumentArray: [#keyPath(Video.liked), 1])
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Video.likeDate), ascending: false)]
        do {
            videos = try coreDataStack.context.fetch(request)
        } catch {
            print(error.localizedDescription)
        }
        let vc = AllVideoTableViewController()
        vc.group = Group(title: "Liked", videos: videos)
        navigationController?.pushViewController(vc, animated: true)
    }

    func showDownlaoded() {
        let vc = DownloadRelatedVideoViewController()
        vc.coreDataStack = coreDataStack
        navigationController?.pushViewController(vc, animated: true)
    }

}


