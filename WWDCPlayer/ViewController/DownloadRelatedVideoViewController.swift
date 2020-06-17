//
//  DownloadRelatedVideoViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/6.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class DownloadRelatedVideoViewController: UIViewController {

    var coreDataStack: CoreDataStack!
    var segmentedControl: UISegmentedControl!
    var videos: [Video] = []

    lazy var downloadedVideosTableView: AllVideoTableViewController = {
        let vc = AllVideoTableViewController()
        let downloadedVideos = fetchDownloadedVideos()
        let group = Group(title: "Downloaded", videos: downloadedVideos)
        vc.group = group
        return vc
    }()

    lazy var downloadingVideoTableView: DownloadViewController = {
        let vc = DownloadViewController()
        vc.downloadItems = ContainerService.shared.shareStore.allDownloadItems
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl = UISegmentedControl()
        segmentedControl.insertSegment(withTitle: "Downloaded", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Downloading", at: 1, animated: false)
        segmentedControl.addTarget(self, action: #selector(segmentedControlAction(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        navigationItem.titleView = segmentedControl
        showDownloadedVideos()
    }

    func fetchDownloadedVideos() -> [Video] {
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Video.downloadData.status), Int16(DownloadData.DownloadStatus.downloaded.rawValue)])
        let videos = (try? coreDataStack.context.fetch(request)) ?? []
        return videos
    }
    
    @objc func segmentedControlAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            showDownloadedVideos()
        case 1:
            showDownloadingVideos()
        default:
            break
        }
    }

    func showDownloadedVideos() {
        downloadingVideoTableView.remove()
        add(downloadedVideosTableView)
        downloadedVideosTableView.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func showDownloadingVideos() {
        downloadedVideosTableView.remove()
        add(downloadingVideoTableView)
        downloadingVideoTableView.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

}
