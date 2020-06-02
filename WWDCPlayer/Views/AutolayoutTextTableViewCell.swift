//
//  AutolayoutTextTableViewCell.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class AutolayoutTextTableViewCell: UITableViewCell {

    static let identifier = "auto-layout-text-cell"

    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setup() {
        contentView.addSubview(label) {
            $0.edges.equalToSuperview().inset(16)
        }
    }

}
