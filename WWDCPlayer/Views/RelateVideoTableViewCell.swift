//
//  RelateVideoTableViewCell.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class RelateVideoTableViewCell: UITableViewCell {

    static let identifier = "relate-video-cell-identifier"

    let label: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        return label
    }()

    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
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
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(13)
        }

        contentView.addSubview(separator) {
            $0.bottom.equalToSuperview()
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(1/UIScreen.main.scale)
        }
    }

}
