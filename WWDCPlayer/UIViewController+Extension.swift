//
//  UIViewController+Extension.swift
//  GIF Creator
//
//  Created by Xianzhao Han on 2020/4/10.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

extension UIViewController {

    func add(_ vc: UIViewController) {
        vc.willMove(toParent: self)
        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        didMove(toParent: nil)
    }

}
