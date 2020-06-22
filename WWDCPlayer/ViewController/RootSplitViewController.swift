//
//  RootSplitViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/21.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class RootSplitViewController: UISplitViewController {

    var coreDataStack: CoreDataStack!
    var videoService: VideoService!
    var subscriptions = Set<AnyCancellable>()

    var slideBarViewController: SlideBarTableViewController!
    var masterViewController: SplitViewController!

    var collectionVC: UIViewController?
    var likedVC: UIViewController?
    var downloadRelatedVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6

        slideBarViewController = SlideBarTableViewController()
        slideBarViewController.didSelectedSubject
            .sink { [weak self] indexPath in
                self?.updateDetail(indexPath: indexPath)
            }
            .store(in: &subscriptions)

        viewControllers = [slideBarViewController]

        maximumPrimaryColumnWidth = 100
        maximumPrimaryColumnWidth = 100

        primaryBackgroundStyle = .sidebar
    }

    func updateDetail(indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            break
        case (0, 2):
            if let vc = collectionVC {
                showDetailViewController(vc, sender: nil)
                return
            }

            let vc = SplitViewController()
            vc.coreDataStack = coreDataStack
            let menuVC = HomeViewController()
            menuVC.coreDataStack = coreDataStack
            menuVC.title = "Collection"
            vc.menuViewController = UINavigationController(rootViewController: menuVC)
            showDetailViewController(vc, sender: nil)
            collectionVC = vc
        case (1, 0):
            if let vc = likedVC {
                showDetailViewController(vc, sender: nil)
                return
            }

            let vc = SplitViewController()
            vc.coreDataStack = coreDataStack
            let menuVC = AllVideoTableViewController()
            menuVC.group = videoService.likedVideos()
            menuVC.title = "Liked"
            vc.menuViewController = UINavigationController(rootViewController: menuVC)
            showDetailViewController(vc, sender: nil)
            likedVC = vc
        case (1, 1):
            if let vc = downloadRelatedVC {
                showDetailViewController(vc, sender: nil)
                return
            }

            let vc = SplitViewController()
            vc.coreDataStack = coreDataStack
            let menuVC = DownloadRelatedVideoViewController()
            menuVC.coreDataStack = coreDataStack
            vc.menuViewController = UINavigationController(rootViewController: menuVC)
            showDetailViewController(vc, sender: nil)
            downloadRelatedVC = vc
        default:
            break
        }
    }

}
