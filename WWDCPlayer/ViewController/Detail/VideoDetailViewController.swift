//
//  VideoDetailViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import Combine
import AVKit

class VideoDetailViewController: UITableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet weak var videoURL: UILabel!
    
    @Published var isLoading = false
    
    var video: Video!
    var videoDetail: VideoDetail?
    var downloaded: Bool!
    var didLoadvideoDetail = PassthroughSubject<VideoDetail, Never>()
    let service = WWDCService()
    let shareStore = ContainerService.shared.shareStore
    var coreDataStack = ContainerService.shared.coreDataStack
    var hdDownloadItem: DownloadItem?
    var sdDownloadItem: DownloadItem?
    var subscriptions = Set<AnyCancellable>()
    var downloadItemSubscriptions = Set<AnyCancellable>()
    var des: String {
        return videoDetail?.description ?? "test description"
    }
    var relatedVideos: [ShortVideoGroup] {
        return videoDetail?.relatedVideos ?? []
    }

    enum Identifier {
        static let name = "name"
        static let header = "header"
        static let relatedVideo = "related-video"
        static let title = "title"
    }

    var likedImage: UIImage? {
        let name = video.isLiked ? "heart.fill" : "heart"
        return UIImage(systemName: name)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard video != nil else {
            isLoading = true
            return
        }

        tableView.separatorStyle = .none

        tableView.register(AutolayoutTextTableViewCell.self, forCellReuseIdentifier: Identifier.title)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier.name)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier.relatedVideo)
        tableView.register(HomeTableHeaderView.self, forHeaderFooterViewReuseIdentifier: Identifier.header)
        tableView.register(AutolayoutTextTableViewCell.self, forCellReuseIdentifier: AutolayoutTextTableViewCell.identifier)
        tableView.register(RelateVideoTableViewCell.self, forCellReuseIdentifier: RelateVideoTableViewCell.identifier)
        tableView.register(IconsTableViewCell.self, forCellReuseIdentifier: IconsTableViewCell.identifier)
        
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

        if downloaded {
            isLoading = false
        } else {
            loadData()
        }
    }
    
    func setupView() {
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(indicator) {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).multipliedBy(0.5)
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
                self.didLoadvideoDetail.send(videoDetail)
                self.setupDownloadItem()
                self.isLoading = false
                self.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }
    
    func setupDownloadItem() {
//        hdDownloadItem = shareStore.allDownloadItems.first(where: { $0.downloadURL.path == self.videoDetail.hd.path })
//        sdDownloadItem = shareStore.allDownloadItems.first(where: { $0.downloadURL.path == self.videoDetail.sd.path })
    }
    
    func hdDownload() {
        guard let videoDetail = videoDetail, let hd = videoDetail.hd else { return }
        let item = download(hd, resolution: .hd)
        hdDownloadItem = item
    }
    
    func sdDownload() {
        guard let videoDetail = videoDetail, let sd = videoDetail.sd else { return }
        let item = download(sd, resolution: .sd)
        sdDownloadItem = item
    }
    
    func download(_ url: URL, resolution: DownloadItem.VideoType) -> DownloadItem {
        let downloadItem = DownloadItem(video: video, resolution: resolution, url: url, m3u8: videoDetail!.m3u8URL, coreDataStack: coreDataStack)
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return UITableView.automaticDimension
        case (3..., _):
            return 44
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isLoading ? 0 : (relatedVideos.count + 3)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 1
        default:
            let index = section - 3
            return relatedVideos[index].videos.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.title, for: indexPath) as! AutolayoutTextTableViewCell
            cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.label.text = video.title
            return cell
        case (0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: AutolayoutTextTableViewCell.identifier, for: indexPath) as! AutolayoutTextTableViewCell
            cell.label.text = des
            cell.label.textColor = .secondaryLabel
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        case (1, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: IconsTableViewCell.identifier, for: indexPath) as! IconsTableViewCell
            var icons = [likedImage]
            if videoDetail?.sd != nil || videoDetail?.hd != nil {
                icons.insert(UIImage(systemName: "square.and.arrow.down"), at: 0)
            }
            cell.icons = icons
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.delegate = self
            return cell
        case (2, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.name, for: indexPath)
            cell.textLabel?.text = "m3u8"
            return cell
        default:
            let index = indexPath.section - 3
            let cell = tableView.dequeueReusableCell(withIdentifier: RelateVideoTableViewCell.identifier, for: indexPath) as! RelateVideoTableViewCell
            let video = relatedVideos[index].videos[indexPath.row]
            cell.label.text = video.name
            cell.backgroundColor = .clear
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section >= 3 else { return nil }

        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifier.header) as? HomeTableHeaderView else {
            fatalError()
        }

        let index = section - 3
        let name = relatedVideos[index].name
        if section == 3 {
            view.label.text = "Related Videos\n\(name)"
        } else {
            view.label.text = name
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 3 {
            return 88
        } else if section > 3 {
            return 44
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

//        switch (indexPath.section, indexPath.row) {
//        case (1, 0):
//            guard hdDownloadItem == nil else { return }
//            hdDownload()
//        case (1, 1):
//            guard sdDownloadItem == nil else { return }
//            sdDownload()
//        case (2, 0):
//            print(videoURL.text ?? "NIL")
//        default:
//            break
//        }
    }
    
}

extension VideoDetailViewController: IconsTableViewCellDelegate {

    func iconsTableViewCell(_ iconsTableViewCell: IconsTableViewCell, didSelectedAt index: Int, source view: UIView) {
        switch index {
        case 0:
            guard videoDetail?.hd != nil || videoDetail?.sd != nil else { return }
            downloadHandler(view)
        case 1:
            likeHandler(view as! UIButton)
        default:
            break
        }
    }

    func downloadHandler(_ sender: UIView) {
        let menu = UIAlertController(title: "下载", message: "选择下载的清晰度", preferredStyle: .actionSheet)
        let sdAction = UIAlertAction(title: "SD", style: .default) { [weak self] _ in
            self?.sdDownload()
        }
        let hdAction = UIAlertAction(title: "HD", style: .default) { [weak self] _ in
            self?.hdDownload()
        }
        if videoDetail?.sd != nil {
            menu.addAction(sdAction)
        }
        if videoDetail?.hd != nil {
            menu.addAction(hdAction)
        }
        menu.popoverPresentationController?.sourceView = sender
        present(menu, animated: true, completion: nil)
    }

    func likeHandler(_ sender: UIButton) {
        if video.isLiked {
            video.liked = 0
        } else {
            video.liked = 1
        }

        coreDataStack.save()
        sender.setImage(likedImage, for: .normal)
    }

}
