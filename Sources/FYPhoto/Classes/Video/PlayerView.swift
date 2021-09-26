//
//  PlayerView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation
import AVFoundation
import UIKit

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            // .resizeAspectFill -> fullScreen
//            playerLayer.videoGravity = .resizeAspectFill
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
