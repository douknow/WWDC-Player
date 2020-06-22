//
//  VideoDetailContainerViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/5.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import AVKit
import Combine
import SnapKit

class VideoDetailContainerViewController: UIViewController {
    
    var infoViewController: VideoDetailViewController!
    var playerView: PlayerView!
    var avPlayer: AVPlayer!
    var video: Video?
    let playerViewAspect: CGFloat = 459.0/817
    var videoDetail: VideoDetail!
    var subscriptions = Set<AnyCancellable>()
    var subtitleViewController: SubtitleTableViewController?

    var playerViewAspectConstraint: Constraint!
    var playerViewBottomConstraint: Constraint!

    var showingSubtitleMenu = false

    var isDownloaded: Bool {
        guard let video = video,
            let downloadData = video.downloadData,
            downloadData.downloadStatus == .downloaded
            else { return false }

        return true
    }

    deinit {
        print("Video detail container deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        setupInfoViewController()
        setupViews()
        
        infoViewController.didLoadvideoDetail
            .sink { [unowned self] in
                self.videoDetail = $0
                self.setupPlayer()
            }
            .store(in: &subscriptions)

        let tapRecongizer = UITapGestureRecognizer(target: self, action: #selector(hideSubtitleChooseMenu))
        playerView.addGestureRecognizer(tapRecongizer)
        tapRecongizer.delegate = self

        if isDownloaded {
            setupPlayer()
        }

        print("video detail container did load")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func setupInfoViewController() {
        infoViewController = storyboard!.instantiateViewController(identifier: "VideoDetailViewController")
        infoViewController.video = video
        infoViewController.downloaded = isDownloaded
    }
    
    func setupViews() {
        navigationController?.navigationBar.isTranslucent = true

        playerView = PlayerView()
        playerView.delegate = self
        view.addSubview(playerView) {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            playerViewAspectConstraint = $0.height.equalTo(self.view.snp.width).multipliedBy(self.playerViewAspect).constraint
            playerViewAspectConstraint.activate()
            playerViewBottomConstraint = $0.bottom.equalToSuperview().constraint
            playerViewBottomConstraint.deactivate()
        }

        infoViewController.willMove(toParent: self)
        view.addSubview(infoViewController.view) {
            $0.left.bottom.right.equalToSuperview()
            $0.top.equalTo(self.playerView.snp.bottom)
        }
        infoViewController.didMove(toParent: self)
    }
    
    func setupPlayer() {
        if isDownloaded {
            let url = Folder.videoFile(for: video!)
            let playerItem = AVPlayerItem(url: url)
            playerView.playerItem = playerItem
            loadSubtitles()
        } else {
            playerView.video = video
            playerView.videoDetail = videoDetail
        }
    }

    func loadSubtitles() {
        guard let video = video else { return }
        playerView.loadStaticSubtitles(by: video)
    }

    @objc func showSubtitleChooseMenu() {
        playerView.hideControlsView()

        let subtitleViewController = SubtitleTableViewController()
        subtitleViewController.delegate = self
        let selectedIndex = playerView.subtitles.firstIndex(where: { $0.name == playerView.selectedSubtitle?.name }) ?? playerView.subtitles.count
        var data = playerView.subtitles.map { $0.name }
        data.append("关闭")
        subtitleViewController.data = data
        subtitleViewController.selected = IndexPath(row: selectedIndex, section: 0)
        subtitleViewController.willMove(toParent: self)
        view.addSubview(subtitleViewController.view)
        subtitleViewController.view.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalTo(self.playerView)
            $0.width.equalTo(200)
        }
        subtitleViewController.didMove(toParent: self)
        self.subtitleViewController = subtitleViewController

        subtitleViewController.view.transform = CGAffineTransform(translationX: 200, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            subtitleViewController.view.transform = .identity
        }, completion: nil)
    }

    @objc func hideSubtitleChooseMenu() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.subtitleViewController?.view.transform = CGAffineTransform(translationX: 200, y: 0)
        }) { _ in
            self.subtitleViewController?.willMove(toParent: nil)
            self.subtitleViewController?.view.removeFromSuperview()
            self.subtitleViewController?.removeFromParent()
            self.subtitleViewController?.didMove(toParent: nil)
            self.subtitleViewController = nil

            self.playerView.showControlsView()
        }
    }

}


extension VideoDetailContainerViewController: PlayerViewDelegate {

    func playerView(_ playerView: PlayerView, subtitleTapped sender: UIButton?) {
        showSubtitleChooseMenu()
    }

    func playerView(_ playerView: PlayerView, completeCache subtitle: Subtitle) {
        let index = playerView.subtitles.firstIndex { $0.url == subtitle.url }!
        subtitleViewController?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    func playerView(_ playerView: PlayerView, fullScreenButtonDidTapped button: UIButton) {
        guard let splitVC = parent as? UISplitViewController else { return }

        switch playerView.screenMode {
        case .normal:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
                splitVC.preferredDisplayMode = .primaryHidden
                self.playerViewAspectConstraint.deactivate()
                self.playerViewBottomConstraint.activate()
                self.view.layoutIfNeeded()
            }, completion: nil)
            playerView.switchScreenMode(to: .fullScreen)
        case .fullScreen:
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                splitVC.preferredDisplayMode = .allVisible
                self.playerViewBottomConstraint.deactivate()
                self.playerViewAspectConstraint.activate()
                self.view.layoutIfNeeded()
            }, completion: nil)
            playerView.switchScreenMode(to: .normal)
        }
    }

}


extension VideoDetailContainerViewController: SubtitleTableViewControllerDelegate {

    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, didSelectedAt indexPath: IndexPath) {
        hideSubtitleChooseMenu()
        if indexPath.row >= playerView.subtitles.count {
            playerView.switchSubtitle(subtitle: nil)
        } else {
            playerView.switchSubtitle(subtitle: playerView.subtitles[indexPath.row])
        }
    }

    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, isLoadingFor indexPath: IndexPath) -> Bool {
        if indexPath.row >= playerView.subtitles.count { return false }
        return !playerView.hasCached(with: playerView.subtitles[indexPath.row])
    }

}

extension VideoDetailContainerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return subtitleViewController != nil
    }

}
