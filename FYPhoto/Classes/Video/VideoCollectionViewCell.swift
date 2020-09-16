//
//  VideoCollectionViewCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/15.
//

import UIKit
import AVFoundation

class VideoDetailCell: UICollectionViewCell {
    var player: AVPlayer
    var activityIndicator = UIActivityIndicatorView(style: .white)
    var playButton = UIButton()

    init(frame: CGRect, url: URL) {
        player = AVPlayer(url: url)
        super.init(frame: frame)

        contentView.addSubview(playButton)
        contentView.addSubview(activityIndicator)

        setupPlayButton()
        setupActivityIndicator()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPlayButton() {
        //        Icons made by <a href="https://www.flaticon.com/authors/those-icons" title="Those Icons">Those Icons</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>
        playButton.setImage("play_button".photoImage, for: .normal)
        playButton.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
        playButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        playButton.center = contentView.center
    }

    func setupActivityIndicator() {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = contentView.center
//        activityIndicator.bringSubviewToFront(contentView)
        activityIndicator.isHidden = true
    }

    @objc func playVideo(_ sender: UIButton) {

    }


}
