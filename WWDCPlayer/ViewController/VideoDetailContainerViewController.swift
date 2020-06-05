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

class VideoDetailContainerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var infoViewController: VideoDetailViewController!
    var playerView: PlayerView!
    var avPlayer: AVPlayer!
    var video: Video!
    let playerViewAspect: CGFloat = 459.0/817
    var videoDetail: VideoDetail!
    var subscriptions = Set<AnyCancellable>()
    var topOffsetConstraint: Constraint!
    var subtitleViewController: SubtitleTableViewController?

    var showingSubtitleMenu = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        infoViewController = storyboard!.instantiateViewController(identifier: "VideoDetailViewController")
        infoViewController.video = video
        setupViews()
        
        infoViewController.didLoadvideoDetail
            .sink { [unowned self] in
                self.videoDetail = $0
                self.setupPlayer()
            }
            .store(in: &subscriptions)

        let tapRecongizer = UITapGestureRecognizer(target: self, action: #selector(hideSubtitleChooseMenu))
        playerView.addGestureRecognizer(tapRecongizer)
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

        topOffsetConstraint.update(offset: view.frame.width * playerViewAspect + UIApplication.shared.statusBarFrame.height)
    }
    
    func setupViews() {        
        navigationController?.navigationBar.isTranslucent = true

        playerView = PlayerView()
        playerView.delegate = self
        view.addSubview(playerView) {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
            $0.height.equalTo(self.view.snp.width).multipliedBy(self.playerViewAspect)
        }

        infoViewController.willMove(toParent: self)
        view.addSubview(infoViewController.view) {
            $0.left.bottom.right.equalToSuperview()
            topOffsetConstraint = $0.top.equalToSuperview().offset(0).constraint
            topOffsetConstraint.activate()
        }
        infoViewController.didMove(toParent: self)
    }
    
    func setupPlayer() {
        playerView.video = video
        playerView.videoDetail = videoDetail
    }

    @objc func showSubtitleChooseMenu() {
        let subtitleViewController = SubtitleTableViewController()
        subtitleViewController.delegate = self
        var data = playerView.subtitles.map { $0.name }
        data.append("关闭")
        subtitleViewController.data = data
        subtitleViewController.selected = IndexPath(row: data.count - 1, section: 0)
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
        }
    }

}


extension VideoDetailContainerViewController: PlayerViewDelegate {

    func playerView(_: PlayerView, subtitleTapped sender: UIButton?) {
        showSubtitleChooseMenu()
    }

    func playerView(_: PlayerView, completeCache subtitle: Subtitle) {
        let index = playerView.subtitles.firstIndex { $0.url == subtitle.url }!
        subtitleViewController?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

}


extension VideoDetailContainerViewController: SubtitleTableViewControllerDelegate {

    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, didSelectedAt indexPath: IndexPath) {
        playerView.switchSubtitle(subtitle: playerView.subtitles[indexPath.row])
    }

    func subtitleTableViewController(_ subtitleTableViewController: SubtitleTableViewController, isLoadingFor indexPath: IndexPath) -> Bool {
        if indexPath.row >= playerView.subtitles.count { return false }
        return !playerView.hasCached(with: playerView.subtitles[indexPath.row])
    }

}
