//
//  HomeViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class CategoryViewController: UITableViewController {

    var coreDataStack: CoreDataStack!

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
        tableView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            // show collection
            showCollection()
        case 1:
            // show topic
            showTopic()
        case 2:
            // show all video
            showAllVideo()
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

}


