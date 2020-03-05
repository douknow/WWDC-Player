//
//  VideoDetailViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine

class VideoDetailViewController: UITableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet weak var videoURL: UILabel!
    @IBOutlet weak var hdDownloadLabel: UILabel!
    @IBOutlet weak var sdDownloadLabel: UILabel!
    
    @Published var isLoading = false
    
    var video: Video!
    var videoDetail: VideoDetail!
    let service = WWDCService()
    let shareStore = ContainerService.shared.shareStore
    var coreDataStack: CoreDataStack!
    var playerViewController: PlayerViewController!
    let playerViewAspect: CGFloat = 459.0/817
    var hdDownloadItem: DownloadItem?
    var sdDownloadItem: DownloadItem?
    var subscriptions = Set<AnyCancellable>()
    var downloadItemSubscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        title = video.title
        
        $isLoading
            .sink { [unowned self] isLoading in
                if isLoading {
                    self.indicator.isHidden = false
                    self.indicator.startAnimating()
                } else {
                    self.indicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)
        
        self.loadData()
    }
    
    func setupView() {
        additionalSafeAreaInsets = UIEdgeInsets(top: view.frame.width * playerViewAspect, left: 0, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(indicator) {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).multipliedBy(0.5)
        }
        
        playerViewController = PlayerViewController()        
        view.addSubview(playerViewController.view) {
            $0.left.equalToSuperview()
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            $0.width.equalToSuperview()
            $0.height.equalTo(self.playerViewController.view.snp.width).multipliedBy(playerViewAspect)
        }
    }
    
    func loadData() {
        isLoading = true
        
        service.videoDetail(by: video)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                // handle error
            }) { [unowned self] videoDetail in
                self.videoDetail = videoDetail
                self.setupDownloadItem()
                self.isLoading = false
                self.titleLabel.text = videoDetail.title
                self.descriptionLabel.text = videoDetail.description
                self.videoURL.text = videoDetail.m3u8URL.absoluteString
                self.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }
    
    func setupDownloadItem() {
        hdDownloadItem = shareStore.allDownloadItems.first(where: { $0.downloadURL.path == self.videoDetail.hd.path })
        if let hdDownloadItem = hdDownloadItem { subscribe(downloadItem: hdDownloadItem, label: hdDownloadLabel) }
        sdDownloadItem = shareStore.allDownloadItems.first(where: { $0.downloadURL.path == self.videoDetail.sd.path })
        if let sdDownloadItem = sdDownloadItem { subscribe(downloadItem: sdDownloadItem, label: sdDownloadLabel) }
    }
    
    func hdDownload() {
        let item = download(videoDetail.hd)
        subscribe(downloadItem: item, label: hdDownloadLabel)
        hdDownloadItem = item
    }
    
    func sdDownload() {
        let item = download(videoDetail.sd)
        subscribe(downloadItem: item, label: sdDownloadLabel)
        sdDownloadItem = item
    }
    
    func download(_ url: URL) -> DownloadItem {
        let downloadItem = DownloadItem(video: video, url: url, coreDataStack: coreDataStack)
        ContainerService.shared.shareStore.insert(downloadItem: downloadItem)
        downloadItem.resume()
        return downloadItem
    }
    
    func subscribe(downloadItem: DownloadItem, label: UILabel) {
        downloadItemSubscriptions = Set<AnyCancellable>()
        downloadItem.$status
            .receive(on: DispatchQueue.main)
            .sink {
                switch $0 {
                case .finished:
                    label.text = "已下载"
                case .paused:
                    label.text = "已暂停"
                default:
                    break 
                }
            }
            .store(in: &downloadItemSubscriptions)
        downloadItem.$downloadProgress
            .receive(on: DispatchQueue.main)
            .map { NumberFormatter.localizedString(from: NSNumber(value: $0), number: .percent) }
            .sink {
                if downloadItem.status == .downloading {
                    label.text = $0
                }                
            }
            .store(in: &downloadItemSubscriptions)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isLoading ? 0 : 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            guard hdDownloadItem == nil else { return }
            hdDownload()
        case (1, 1):
            guard sdDownloadItem == nil else { return }
            sdDownload()
        case (2, 0):
            print(videoURL.text ?? "NIL")
        default: 
            break
        }
    }
    
    @IBAction func resumeButtonTappedHandler(_ sender: Any?) {
        playerViewController.player?.play()
    }
}
