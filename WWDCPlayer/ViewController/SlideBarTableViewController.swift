//
//  SlideBarTableViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/21.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class SlideBarTableViewController: UITableViewController {

    let imageCellIdentifier = "image-cell-identifier"

    var selectedIndexPath: IndexPath?
    let didSelectedSubject = PassthroughSubject<IndexPath, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(SlideBarTableViewCell.self, forCellReuseIdentifier: imageCellIdentifier)
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false

        didSelectedSubject.send(IndexPath(row: 0, section: 0))
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: imageCellIdentifier, for: indexPath) as? SlideBarTableViewCell else { fatalError() }

        let imageName: String
        let unSelectedImageName: String

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            imageName = "sun.min.fill"
            unSelectedImageName = "sun.min"
        case (0, 1):
            imageName = "star.fill"
            unSelectedImageName = "star"
        case (0, 2):
            imageName = "square.stack.3d.up.fill"
            unSelectedImageName = "square.stack.3d.up"
        case (1, 0):
            imageName = "heart.fill"
            unSelectedImageName = "heart"
        case (1, 1):
            imageName = "square.and.arrow.down.fill"
            unSelectedImageName = "square.and.arrow.down"
        default:
            imageName = ""
            unSelectedImageName = ""
        }

        let image = UIImage(systemName: imageName)
        let config = UIImage.SymbolConfiguration(weight: .light)
        let unSelectedImage = UIImage(systemName: unSelectedImageName, withConfiguration: config)
        cell.config(image: image, unSelectedImage: unSelectedImage, selected: selectedIndexPath == indexPath)
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        didSelectedSubject.send(indexPath)
        tableView.reloadData()
    }

}

class SlideBarTableViewCell: UITableViewCell {

    var contentImageView: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentImageView = UIImageView()
        contentImageView.contentMode = .scaleAspectFit
        contentView.addSubview(contentImageView) {
            $0.width.height.equalTo(32)
            $0.center.equalToSuperview()
        }
    }

    func config(image: UIImage?, unSelectedImage: UIImage?, selected: Bool) {
        contentImageView.image = selected ? image : unSelectedImage
        contentImageView.tintColor = selected ? .systemBlue : .label
    }

}
