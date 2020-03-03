//
//  DownloadItemCell.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class DownloadItemCell: UITableViewCell {
    
    static let identifier = "DownloadItemCellIdentifier"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIView!
    @IBOutlet weak var downloadProgressCompleteView: UIView!
    @IBOutlet weak var progressTrailingConstraint: NSLayoutConstraint!
    
    var downloadItem: DownloadItem!
    var subscriptions = Set<AnyCancellable>() 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        downloadProgressView.layer.cornerRadius = 5
        downloadProgressCompleteView.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func config(item: DownloadItem) {
        downloadItem = item
        
        subscriptions.removeAll()
        titleLabel.text = item.video.title
        
        item.$downloadProgress
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] progress in
                self.percentLabel.text = String(format: "%.2f", arguments: [progress * 100]) + " %"
                let constant = CGFloat((1 - progress)) * self.downloadProgressView.frame.width
                self.progressTrailingConstraint.constant = constant
                self.downloadProgressView.layoutIfNeeded()
            }
            .store(in: &subscriptions)
        
        item.$status
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] status in
                let text: String
                let downloadImage = UIImage(systemName: "arrow.down.circle")
                let pauseImage = UIImage(systemName: "pause.circle")
                switch status {
                case .unstart:
                    text = "开始"
                    self.actionButton.setImage(downloadImage, for: .normal)
                case .downloading:
                    text = "下载中"
                    self.actionButton.setImage(pauseImage, for: .normal)
                case .paused:
                    text = "已暂停"
                    self.actionButton.setImage(downloadImage, for: .normal)
                case .finished:
                    text = "已完成"
                }
                self.statusLabel.text = text
                self.actionButton.isHidden = status == .finished
            }
            .store(in: &subscriptions)
    }
    
    @IBAction func actionButtionHandler(_ sender: Any?) {
        switch downloadItem.status {
        case .downloading:
            downloadItem.pause()
        case .paused:
            downloadItem.resume()
        default: 
            break
        }
    }  

}
