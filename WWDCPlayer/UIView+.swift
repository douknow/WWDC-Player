//
//  UIView+.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {
    
    /// Add subview and setup constraint use snapkit
    /// - Parameters:
    ///   - view: subview
    ///   - closure: maker closure
    func addSubview(_ view: UIView, closure: ((ConstraintMaker) -> Void) = { _ in }) {
        addSubview(view)
        view.snp.makeConstraints(closure)
    }
    
}
