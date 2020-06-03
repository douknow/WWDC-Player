//
//  IconsTableViewCell.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

protocol IconsTableViewCellDelegate: class {
    func iconsTableViewCell(_ iconsTableViewCell: IconsTableViewCell, didSelectedAt index: Int, source view: UIView)
}

class IconsTableViewCell: UITableViewCell {

    static let identifier = "icon-table-view-cell"

    var stackView: UIStackView!
    var icons: [UIImage?] = [] {
        didSet {
            configIcons()
        }
    }

    weak var delegate: IconsTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
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

    func setupView() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        contentView.addSubview(stackView) {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(10)
        }
    }

    func configIcons() {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
            stackView.removeArrangedSubview(view)
        }

        for icon in icons {
            let button = UIButton(type: .system)
            button.tintColor = .label
            button.setImage(icon, for: .normal)
            button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    @objc func buttonAction(_ sender: Any?) {
        guard let button = sender as? UIButton else { return }
        if let index = stackView.arrangedSubviews.firstIndex(of: button) {
            delegate?.iconsTableViewCell(self, didSelectedAt: index, source: button)
        }
    }

}
