//
//  PlayerView.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import AVKit

protocol PlayerViewDelegate: class {
    func playerView(_: PlayerView, subtitleTapped sender: UIButton?)
    func playerView(_: PlayerView, completeCache subtitle: Subtitle)
}

class PlayerView: VideoView {

    var playButton: UIButton!
    var indicator: UIActivityIndicatorView!
    var progressView: UISlider!
    var currentTimeLabel: UILabel!
    var allTimeLabel: UILabel!
    var resolutionButton: UIButton!
    var subtitleButton: UIButton!

    var statusObserver: NSKeyValueObservation?

    private var playerContext = 0
    private var isPlayBufferEmptyContext = 0
    private var isPlaybackLikelyToKeepUpContext = 0

    let playImage = UIImage(systemName: "play.fill")
    let pauseImage = UIImage(systemName: "pause.fill")
    let refreshImage = UIImage(systemName: "arrow.clockwise")

    var video: Video?
    let downloader = Downloader()
    var subtitles: [Subtitle] = []
    var subtitleCache: [URL: [SubtitleLine]] = [:]

    weak var delegate: PlayerViewDelegate?

    var videoDetail: VideoDetail? {
        didSet {
            if let videoDetail = videoDetail {
//                let testURL = URL(string: "https://vod-progressive.akamaized.net/exp=1591268366~acl=%2A%2F1141237980.mp4%2A~hmac=893f4bd3ebed6dba792d0ba3e74370de9ba1960a1e9583a9c8f76540cc02ce26/vimeo-prod-skyfire-std-us/01/4821/11/299108997/1141237980.mp4?download=1&filename=Pexels+Videos+1570920.mp4")!
                let playerItem = AVPlayerItem(url: videoDetail.sd)
                self.playerItem = playerItem
                loadSubtitles()
            }
        }
    }

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
            $0.leading.bottom.equalToSuperview().inset(16)
        }

        indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        addSubview(indicator) {
            $0.center.equalTo(self.playButton)
        }

        resolutionButton = UIButton(type: .system)
        resolutionButton.setTitle("SD", for: .normal)
        resolutionButton.titleLabel?.font = .systemFont(ofSize: 20)
        resolutionButton.addTarget(self, action: #selector(resolutionButtonAction(_:)), for: .touchUpInside)

        subtitleButton = UIButton(type: .system)
        subtitleButton.setTitle("字幕", for: .normal)
        subtitleButton.titleLabel?.font = .systemFont(ofSize: 18)
        subtitleButton.addTarget(self, action: #selector(subtitleButtonAction), for: .touchUpInside)
        subtitleButton.isEnabled = false

        currentTimeLabel = UILabel()
        currentTimeLabel.text = "00:00"
        currentTimeLabel.snp.makeConstraints {
            $0.width.equalTo(47)
        }

        progressView = UISlider()
        progressView.value = 0
        progressView.setThumbImage(UIImage(systemName: "rhombus.fill"), for: .normal)
        progressView.setContentHuggingPriority(.init(1), for: .horizontal)

        allTimeLabel = UILabel()
        allTimeLabel.text = "00:00"
        allTimeLabel.snp.makeConstraints {
            $0.width.equalTo(47)
        }

        let stackView = UIStackView(arrangedSubviews: [currentTimeLabel, progressView, allTimeLabel, resolutionButton, subtitleButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        addSubview(stackView) {
            $0.leading.equalTo(self.playButton.snp.trailing).offset(16)
            $0.centerY.equalTo(self.playButton)
            $0.trailing.equalToSuperview().inset(16)
        }
    }

    func setupObserver(_ playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.old, .new], context: &isPlayBufferEmptyContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.old, .new], context: &isPlaybackLikelyToKeepUpContext)

        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0/60, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] time in
            self?.currentTimeLabel.text = time.seconds.hourSecondsFormat
            let percent = time.seconds / playerItem.duration.seconds
            if !(self?.progressView.isHighlighted ?? true) {
                self?.progressView.value = Float(percent)
            }
            if percent == 1 {
                self?.playButton.setImage(self?.refreshImage, for: .normal)
            }
        })
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if context == &isPlayBufferEmptyContext {
            print("Loading buffer ....")
        }

        if context == &isPlaybackLikelyToKeepUpContext {
            print("Can play right now ...")
            DispatchQueue.main.async { [weak self] in
                self?.indicator.stopAnimating()
                self?.playButton.isHidden = false
            }
        }

        guard context == &playerContext else {
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
                print("ready to play ...")
                // 1. hide loading animation
                // 2. show play button
                DispatchQueue.main.async { [unowned self] in
                    self.configInfo()
                }
            case .failed:
                print("failture")
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
            if playerItem?.currentTime() == playerItem?.duration {
                playerItem?.seek(to: .zero, completionHandler: nil)
            }

            player?.play()
            playButton.setImage(pauseImage, for: .normal)
        } else {
            player?.pause()
            playButton.setImage(playImage, for: .normal)
        }
    }

    func configInfo() {
        guard let item = playerItem else { return }
        allTimeLabel.text = item.duration.seconds.hourSecondsFormat
    }

    @objc func resolutionButtonAction(_ sender: UIButton) {
        let menu = UIAlertController(title: "清晰度", message: nil, preferredStyle: .actionSheet)
        let sdAction = UIAlertAction(title: "SD", style: .default) { [unowned self] _ in
            guard let url = self.videoDetail?.sd else { return }
            let item = AVPlayerItem(url: url)
            self.playerItem = item
            sender.setTitle("SD", for: .normal)
        }
        let hdAction = UIAlertAction(title: "HD", style: .default) { [unowned self] _ in
            guard let url = self.videoDetail?.hd else { return }
            let item = AVPlayerItem(url: url)
            self.playerItem = item
            sender.setTitle("HD", for: .normal)
        }
        menu.addAction(sdAction)
        menu.addAction(hdAction)
        menu.popoverPresentationController?.sourceView = sender
        let splitVC = window?.rootViewController as! SplitViewController
        let vc = splitVC.viewControllers.last
        vc?.present(menu, animated: true, completion: nil)
    }

    func loadSubtitles() {
        guard let link = videoDetail?.m3u8URL else { return }

        downloader.downloadSubtitles(link: link) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let subtitles):
                    print("download \(subtitles.count) subtitles")
                    self.subtitles = subtitles.filter { $0.groupId == "subs" }
                    self.subtitleButton.isEnabled = true
                    self.subtitles.forEach {
                        self.downloader.downloadSubtitleContent(subtitle: $0) { result in
                            switch result {
                            case .success(let args):
                                let (subtitle, content) = args
                                let lines = self.downloader.parseSubtitleContent(content: content)
                                self.subtitleCache[subtitle.url] = lines
                                DispatchQueue.main.async {
                                    self.delegate?.playerView(self, completeCache: subtitle)
                                }
                            case .failure(let error):
                                // handle error
                                break
                            }
                        }
                    }
                case .failure(let error):
                    print("download subtitle has an error: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func subtitleButtonAction() {
        delegate?.playerView(self, subtitleTapped: nil)
    }

    func switchSubtitle(subtitle: Subtitle) {
        print("switch to subtitle language: \(subtitle.language)")
    }

    func hasCached(with subtitle: Subtitle) -> Bool {
        return subtitleCache[subtitle.url] != nil
    }

}

extension Double {

    var hourSecondsFormat: String {
        let duration = self
        let hour = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let hourStr = hour < 10 ? "0\(hour)" : "\(hour)"
        let secondsStr = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "\(hourStr):\(secondsStr)"
    }

}
