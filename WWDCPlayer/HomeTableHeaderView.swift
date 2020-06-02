//
//  HomeTableHeaderView.swift
//  ABooks
//
//  Created by Xianzhao Han on 2020/3/20.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class HomeTableHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "HomeTableHeaderView" 
    
    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .label
        addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }
    
}
