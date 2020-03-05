//
//  PlayerContainerViewController.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/5.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import AVKit
import Combine

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    
    let url = PassthroughSubject<URL, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController!
    
    var isPlaying: Bool {
        player.rate > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isUserInteractionEnabled = false
        
        url
            .prefix(1)
            .sink(receiveValue: { [unowned self] url in
                self.view.isUserInteractionEnabled = true
                self.setupPlayer(url)
            })
            .store(in: &subscriptions)
    }
    
    func setupPlayer(_ url: URL) {
        let player = AVPlayer(url: url)
        self.player = player
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.delegate = self
        playerViewController.showsPlaybackControls = false
        playerViewController.videoGravity = .resizeAspect
        playerViewController.player = player
        playerViewController.willMove(toParent: self)
        view.addSubview(playerViewController.view) {
            $0.edges.equalToSuperview()
        }
        playerViewController.didMove(toParent: self)
        self.playerViewController = playerViewController
    }
    
    func updateStatus() {
        UIView.animate(withDuration: 0.25) { 
            self.playButton.isHidden = self.isPlaying
        }
    }
    
    @IBAction func play(_ sender: Any?) {
        player.play()
        updateStatus()
    }
    
    @IBAction func resume() {
        player.pause()
        updateStatus()
    } 
}

extension PlayerViewController: AVPlayerViewControllerDelegate {
    
    
    
}
