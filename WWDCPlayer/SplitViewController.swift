//
//  SplitViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/1.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
    }

}

extension SplitViewController: UISplitViewControllerDelegate {

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }

}
