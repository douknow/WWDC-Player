//
//  PlayerView.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import AVKit

class PlayerView: VideoView {

    var playButton: UIButton!
    var indicator: UIActivityIndicatorView!

    var statusObserver: NSKeyValueObservation?

    private var playerContext = 0
    private var isPlayBufferEmptyContext = 0

    let playImage = UIImage(systemName: "play.fill")
    let pauseImage = UIImage(systemName: "pause.fill")

    var playerItem: AVPlayerItem? {
        get {
            return player?.currentItem
        }
        set {
            if let item = newValue {
                player = AVPlayer(playerItem: item)
                setupObserver(item)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.isHidden = true
        playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        addSubview(playButton) {
            $0.width.height.equalTo(44)
            $0.left.bottom.equalToSuperview().inset(16)
        }

        indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        addSubview(indicator) {
            $0.center.equalTo(self.playButton)
        }
    }

    func setupObserver(_ playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.old, .new], context: &isPlayBufferEmptyContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if context == &isPlayBufferEmptyContext {
            print("laoding buffer ....")
        }

        guard context == &playerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayer.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayer.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            switch status {
            case .readyToPlay:
                print("ready to play")
                // 1. hide loading animation
                // 2. show play button
                indicator.stopAnimating()
                playButton.isHidden = false
            case .failed:
                break
            case .unknown:
                print("unknow")
                break
                // show loading animation
            @unknown default:
                break
            }
        }
    }

    @objc func playButtonAction() {
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(pauseImage, for: .normal)
        } else {
            player?.pause()
            playButton.setImage(playImage, for: .normal)
        }
    }

}
