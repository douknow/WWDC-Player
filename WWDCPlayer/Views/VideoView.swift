//
//  VideoView.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/6/3.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit
import AVKit

class VideoView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

}
