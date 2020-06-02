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
    var playerViewController: AVPlayerViewController!
    var avPlayer: AVPlayer!
    var video: Video!
    let playerViewAspect: CGFloat = 459.0/817
    var videoDetail: VideoDetail!
    var subscriptions = Set<AnyCancellable>()
    var topOffsetConstraint: Constraint!

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
        
        playerViewController = AVPlayerViewController()
        playerViewController.willMove(toParent: self)
        view.addSubview(playerViewController.view) {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height)
            $0.height.equalTo(self.view.snp.width).multipliedBy(self.playerViewAspect)
        }
        playerViewController.didMove(toParent: self)

        infoViewController.willMove(toParent: self)
        view.addSubview(infoViewController.view) {
            $0.left.bottom.right.equalToSuperview()
            topOffsetConstraint = $0.top.equalToSuperview().offset(0).constraint
            topOffsetConstraint.activate()
        }
        infoViewController.didMove(toParent: self)
    }
    
    func setupPlayer() {
        avPlayer = AVPlayer(url: videoDetail.m3u8URL)
        playerViewController.player = avPlayer
        avPlayer.play()
    }

}
