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
    var player: AVPlayer? {
        willSet {
            if newValue == nil {
                playerLayer?.removeFromSuperlayer()
                playerLayer = nil
                return
            } else {
                if let layer = playerLayer {
                    layer.removeFromSuperlayer()
                }
                playerLayer = nil
                let playerLayer = AVPlayerLayer(player: newValue)
                playerLayer.frame = contentView.bounds
                contentView.layer.addSublayer(playerLayer)
                self.playerLayer = playerLayer

                contentView.bringSubviewToFront(playButton)
            }
        }
    }
    var playerLayer: AVPlayerLayer?

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
        // TODO: TODO Use true image 😴zZ
        return imageView.image ?? "cover_placeholder".photoImage
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(playButton)
        contentView.addSubview(activityIndicator)

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
        playerLayer?.frame = contentView.bounds

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
        if url.isFileURL {
            self.photo.underlyingImage = UIImage(contentsOfFile: url.path)
        } else {
            activityIndicator.isHidden = false
            contentView.bringSubviewToFront(activityIndicator)
            activityIndicator.startAnimating()
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { (image, _, error, _, _, _) in
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    if let image = image {
                        self.photo.underlyingImage = image
                    } else if error != nil {
                        self.displayImageFailure()
                    }
                }
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
                    self.player = AVPlayer(playerItem: item)
                }
            }
//            print("video info: \(info)")
        }
    }

    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)

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
