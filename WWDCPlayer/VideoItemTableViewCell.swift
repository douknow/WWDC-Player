//
//  VideoItemTableViewCell.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Kingfisher

class VideoItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!

    var isSelection = false {
        didSet {
            updateStyle(isSelection)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let recognizer = UIHoverGestureRecognizer(target: self, action: #selector(hoverAction(_:)))
        addGestureRecognizer(recognizer)

        selectionStyle = .none
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        previewImageView.layer.cornerRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func config(_ video: Video) {
        previewImageView.kf.setImage(with: video.previewImageURL)
        titleLabel.text = video.title
        tagLabel.text = video.focus
    }

    @objc func hoverAction(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if !isSelection {
                backgroundColor = .systemGray6
                print("hover start: un selected and set background")
            }
        case .ended, .cancelled:
            if !isSelection {
                backgroundColor = .systemBackground
            }
        default:
            break
        }
    }

    func updateStyle(_ isSelected: Bool) {
        let bgColor = isSelected ? UIColor.systemBlue : .clear
        backgroundColor = bgColor
    }
    
}
