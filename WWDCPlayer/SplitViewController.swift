//
//  SplitViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    var coreDataStack: CoreDataStack!
    var group: Group!

    var menuViewController: UIViewController!
    var detailViewController: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6

        detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemBlue

        viewControllers = [menuViewController, detailViewController]
    }

}
