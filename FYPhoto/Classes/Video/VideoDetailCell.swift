//
//  VideoCollectionViewCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/15.
//

import UIKit
import AVFoundation
import Photos
import SDWebImage

class VideoDetailCell: UICollectionViewCell {
    var playerView = PlayerView()

    var player: AVPlayer?

    var activityIndicator = UIActivityIndicatorView(style: .white)
    var playButton = UIButton()
    var imageView = PhotosDetectingImageView()

    var photo: PhotoProtocol! {
        didSet {
            activityIndicator.isHidden = true
            if photo != nil {
                if let image = photo.underlyingImage {
                    display(image: image)
                } else if let asset = photo.asset {
                    display(asset: asset, targetSize: photo.assetSize ?? bounds.size)
                } else if let url = photo.url {
                    display(url: url)
                } else {
                    displayImageFailure()
                }
                setupPlayer(photo)
            }
        }
    }

    func setupPlayer(_ photo: PhotoProtocol) {
        if let asset = photo.asset {
            setupPlayer(asset: asset)
        } else if let url = photo.url {
            setupPlayer(url: url)
        }
    }

    var timeObserverToken: Any?

    var image: UIImage? {        
        return imageView.image ?? "cover_placeholder".photoImage
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        contentView.backgroundColor = .white
        contentView.addSubview(imageView)
        imageView.isHidden = true
        contentView.addSubview(playerView)

        contentView.addSubview(playButton)
        contentView.addSubview(activityIndicator)

        imageView.backgroundColor = .white
        
        imageView.delegate = self
        imageView.contentMode = .scaleAspectFit

        setupPlayButton()
        setupActivityIndicator()

        makeConstraints()
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("video cell deinit ☠️☠️☠️")
        player?.pause()
        if let timeObserver = timeObserverToken {
            player?.removeTimeObserver(timeObserver)
        }
        player = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
        activityIndicator.isHidden = true
    }

    @objc func playVideo(_ sender: UIButton) {
        print(#function)

        guard let player = player else { return }
        player.play()
        addBoundaryTimeObserverForPlayer(player, at: player.currentTime())
        playButton.isHidden = true
//        imageView.isHidden = true
        contentView.bringSubviewToFront(playerView)
    }

    func stopPlayingIfNeeded() {
        guard let player = player else {
            return
        }
        player.pause()
        player.seek(to: .zero)
        playButton.isHidden = false
    }

    func display(url: URL) {
        photo.generateThumbnail(url, size: .zero) { (image) in
            if let image = image {
                self.display(image: image)
            } else {
                self.displayErrorThumbnail()
            }
        }
    }

    func display(image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        setNeedsDisplay()
    }

    func display(asset: PHAsset, targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: PHImageContentMode.aspectFit,
                                              options: options) { [weak self] (image, info) in
            if let image = image {
                self?.photo.underlyingImage = image
            } else {
                self?.displayImageFailure()
            }
        }
    }

    func displayImageFailure() {
        imageView.image = "ImageError".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }


    func displayErrorThumbnail() {
        imageView.image = "Browser-ErrorLoading".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }

    func setupPlayer(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, error, stop, info in
            print("request video from icloud progress: \(progress)")
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (item, info) in
            if let item = item {
                if let player = self.player {
                    player.pause()
                    player.replaceCurrentItem(with: item)
                } else {
                    let player = AVPlayer(playerItem: item)
                    self.playerView.player = player
                    self.player = player
                }
            }
//            print("video info: \(info)")
        }
    }

    func setupPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        if let player = self.player {
            player.pause()
            player.replaceCurrentItem(with: playerItem)
        } else {
            let player = AVPlayer(playerItem: playerItem)
            self.playerView.player = player
            self.player = player
        }
//        player?.seek(to: .zero)
    }

    func addBoundaryTimeObserverForPlayer(_ player: AVPlayer, at currentTime: CMTime) {
        guard let item = player.currentItem else { return }
        var times = [NSValue]()
        // Set initial time to zero
        var currentTime = currentTime
        // Divide the asset's duration into quarters.
        let interval = CMTimeMultiplyByFloat64(item.duration, multiplier: 1)

        // Build boundary times at 25%, 50%, 75%, 100%
        while currentTime < item.duration {
            currentTime = currentTime + interval
            times.append(NSValue(time: currentTime))
        }

        // Add time observer. Observe boundary time changes on the main queue.
        timeObserverToken = player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            // Update UI
            guard let self = self else { return }
            self.playButton.isHidden = false
            player.seek(to: .zero)
            if let observer = self.timeObserverToken {
                player.removeTimeObserver(observer)
            }
            self.timeObserverToken = nil
        }
    }

    func makeConstraints() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40),
            activityIndicator.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}

extension VideoDetailCell: PhotosDetectingImageViewDelegate {
    func handleImageViewSingleTap(_ touchPoint: CGPoint) {
//        routerEvent(name: ImageViewTap.singleTap.rawValue, userInfo: nil)
        player?.pause()
        playButton.isHidden = false
    }

    func handleImageViewDoubleTap(_ touchPoint: CGPoint) {

    }

}
