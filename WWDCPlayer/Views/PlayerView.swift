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
    var controlsView: UIView!
    var subtitleView: UIView!
    var subtitleLabel: UILabel!

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
    var selectedSubtitle: Subtitle?
    var selectedSubtitleLines: [SubtitleLine]?

    private var shouldUpdateProgressBar = true

    weak var delegate: PlayerViewDelegate?

    var videoDetail: VideoDetail? {
        didSet {
            if let videoDetail = videoDetail {
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

//        let hoverRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(hoveringAction(_:)))
//        addGestureRecognizer(hoverRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        controlsView = UIView()
        controlsView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        controlsView.layer.cornerRadius = 6
        addSubview(controlsView) {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-10)
            $0.height.equalTo(44)
        }

        playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.alpha = 0
        playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        playButton.snp.makeConstraints {
            $0.width.height.equalTo(44)
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
        currentTimeLabel.textColor = .systemBackground
        currentTimeLabel.snp.makeConstraints {
            $0.width.equalTo(47)
        }

        progressView = VideoProgressBar()
        progressView.value = 0
        progressView.setThumbImage(UIImage(systemName: "rhombus.fill"), for: .normal)
        progressView.setContentHuggingPriority(.init(1), for: .horizontal)
        progressView.addTarget(self, action: #selector(progressTouchDownAction(_:)), for: .touchDown)
        progressView.addTarget(self, action: #selector(progressValueChangedAction(_:)), for: .valueChanged)
        progressView.addTarget(self, action: #selector(progressBarTouchUpAction(_:)), for: .touchUpInside)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(progressBarTapAction(_:)))
        progressView.addGestureRecognizer(tapRecognizer)

        allTimeLabel = UILabel()
        allTimeLabel.text = "00:00"
        allTimeLabel.textColor = .systemBackground
        allTimeLabel.snp.makeConstraints {
            $0.width.equalTo(47)
        }

        let stackView = UIStackView(arrangedSubviews: [playButton, currentTimeLabel, progressView, allTimeLabel, resolutionButton, subtitleButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        controlsView.addSubview(stackView) {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }

        indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        controlsView.addSubview(indicator) {
            $0.center.equalTo(self.playButton)
        }

        subtitleView = UIView()
        subtitleView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        subtitleView.layer.cornerRadius = 8
        addSubview(subtitleView) {
            $0.leading.equalTo(self.controlsView.snp.leading)
            $0.bottom.equalTo(self.controlsView.snp.top).offset(-10)
        }

        subtitleLabel = UILabel()
        subtitleLabel.textColor = .systemBackground
        subtitleLabel.text = " "
        subtitleLabel.numberOfLines = 0
        subtitleView.addSubview(subtitleLabel) {
            $0.edges.equalToSuperview().inset(10)
        }
    }

    func setupObserver(_ playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.old, .new], context: &isPlayBufferEmptyContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.old, .new], context: &isPlaybackLikelyToKeepUpContext)

        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0/60, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] time in
            let percent = time.seconds / playerItem.duration.seconds

            if self?.shouldUpdateProgressBar ?? false {
                self?.progressView.value = Float(percent)
                self?.currentTimeLabel.text = time.seconds.hourSecondsFormat
            }

            if percent == 1 {
                self?.playButton.setImage(self?.refreshImage, for: .normal)
            }
            self?.updateCurrentSubtitle(for: time)
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
                self?.playButton.alpha = 1
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
                                self.completeDownloadSubtitle(subtitle: subtitle, content: content)
                            case .failure(let error):
                                print("Download subtitle error:  \(error.localizedDescription)")
                            }
                        }
                    }
                case .failure(let error):
                    print("download subtitle has an error: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadStaticSubtitles(by video: Video) {
        guard let downloadData = video.downloadData else { return }
        var subtitles = Folder.subtitles(video: video, for: downloadData.resolution)
        if subtitles.isEmpty {
            subtitles = Folder.subtitles(video: video, for: downloadData.resolution == .hd ? .sd : .hd)
        }
        self.subtitles = subtitles
        subtitles
            .map { subtitle -> (Subtitle, String) in (subtitle, try! String(contentsOf: subtitle.url)) }
            .forEach { args in
                completeDownloadSubtitle(subtitle: args.0, content: args.1)
            }
    }

    func completeDownloadSubtitle(subtitle: Subtitle, content: String) {
        let lines = self.downloader.parseSubtitleContent(content: content)
        subtitleCache[subtitle.url] = lines
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.subtitleButton.isEnabled = true
            self.delegate?.playerView(self, completeCache: subtitle)
        }
    }

    @objc func subtitleButtonAction() {
        delegate?.playerView(self, subtitleTapped: nil)
    }

    func switchSubtitle(subtitle: Subtitle?) {
        print("switch to subtitle language: \(subtitle?.language ?? "NIL")")
        if let subtitle = subtitle {
            let subtitleLines = subtitleCache[subtitle.url]
            showSubtitle()
            selectedSubtitle = subtitle
            selectedSubtitleLines = subtitleLines
            if let time = playerItem?.currentTime() {
                updateCurrentSubtitle(for: time)
            }
        } else {
            selectedSubtitle = nil
            selectedSubtitleLines = nil
            closeSubtitle()
        }
    }

    func hasCached(with subtitle: Subtitle) -> Bool {
        return subtitleCache[subtitle.url] != nil
    }

    @objc func hoveringAction(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state  {
        case .began:
            showControlsView()
//        case .changed:
//            showControlsView()
        case .ended, .cancelled:
            hideControlsView()
        default:
            break
        }
    }

    func hideControlsView() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.controlsView.alpha = 0
        }, completion: nil)
    }

    func showControlsView() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            self.controlsView.alpha = 1
        }, completion: nil)
    }

    func updateCurrentSubtitle(for time: CMTime) {
        guard let subtitleLines = selectedSubtitleLines else { return }
        let seconds = time.seconds
        guard let subtitleLine = subtitleLines.first(where: { subtitleLine -> Bool in
            return seconds >= subtitleLine.startTime && seconds < subtitleLine.endTime
        }) else { return }
        subtitleLabel.text = subtitleLine.value
    }

    func closeSubtitle() {
        guard !subtitleView.isHidden else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn], animations: {
            self.subtitleView.alpha = 0
        }) { _ in
            self.subtitleView.isHidden = true
        }
    }

    func showSubtitle() {
        guard subtitleView.isHidden else { return }
        subtitleView.isHidden = false
        subtitleView.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            self.subtitleView.alpha = 1
        })
    }

    @objc func progressValueChangedAction(_ sender: UISlider) {
        guard let duration = playerItem?.duration else { return }
        let current = CMTimeMultiplyByFloat64(duration, multiplier: Float64(sender.value))
        currentTimeLabel.text = current.seconds.hourSecondsFormat
    }

    @objc func progressTouchDownAction(_ sender: UISlider) {
        print("touch down")
        shouldUpdateProgressBar = false
    }

    @objc func progressBarTouchUpAction(_ sender: UISlider) {

        print("Slider did touch up : \(sender.value)")

        updatePlayerProgress(to: progressView.value)
    }

    @objc func progressBarTapAction(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended, .cancelled:
            print("slider did tap up: \(progressView.value)")
            updatePlayerProgress(to: progressView.value)
        default:
            break
        }
    }

    func updatePlayerProgress(to progress: Float) {
        guard let playerItem = playerItem else { return }
        shouldUpdateProgressBar = false
        let allTime = playerItem.duration
        let current = CMTimeMultiplyByFloat64(allTime, multiplier: Float64(progress))
        currentTimeLabel.text = current.seconds.hourSecondsFormat
        playerItem.seek(to: current, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { _ in
            self.shouldUpdateProgressBar = true
        })
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
