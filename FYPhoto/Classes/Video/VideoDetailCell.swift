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
import MobileCoreServices

class VideoDetailCell: UICollectionViewCell {
    var playerView = PlayerView()

    var activityIndicator = UIActivityIndicatorView(style: .white)

    var imageView = UIImageView()

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
            }
        }
    }

    var image: UIImage? {
        return imageView.image ?? "cover_placeholder".photoImage
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        contentView.backgroundColor = .white
        contentView.addSubview(imageView)
        contentView.addSubview(playerView)

        contentView.addSubview(activityIndicator)

        imageView.backgroundColor = .black

        imageView.contentMode = .scaleAspectFit

        setupActivityIndicator()


        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapVideoCell(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapVideoCell(_:)))
        tap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(tap)

        makeConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        playerView.player = nil
    }

    deinit {
        print("video cell deinit ☠️☠️☠️")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    fileprivate func setupActivityIndicator() {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = contentView.center
        activityIndicator.isHidden = true
    }

    fileprivate func display(url: URL) {
        activityIndicator.startAnimating()
        photo.generateThumbnail(url, size: .zero) { (image) in
            self.activityIndicator.stopAnimating()
            if let image = image {
                self.photo.underlyingImage = image
            } else {
                self.displayErrorThumbnail()
            }
        }
    }

    fileprivate func display(image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        setNeedsDisplay()
    }

    fileprivate func display(asset: PHAsset, targetSize: CGSize) {
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

    fileprivate func displayImageFailure() {
        imageView.image = "ImageError".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }

    fileprivate func displayErrorThumbnail() {
        imageView.image = "Browser-ErrorLoading".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }

    @objc func tapVideoCell(_ gesture: UITapGestureRecognizer) {
        routerEvent(name: ImageViewTap.singleTap.rawValue, userInfo: nil)
    }

    @objc func doubleTapVideoCell(_ gesture: UITapGestureRecognizer) {
        var info = [String: Any]()
        info["mediaType"] = kUTTypeVideo
        routerEvent(name: ImageViewTap.doubleTap.rawValue, userInfo: info)
    }

    fileprivate func makeConstraints() {
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
//        playButton.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            playButton.widthAnchor.constraint(equalToConstant: 50),
//            playButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40),
            activityIndicator.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
