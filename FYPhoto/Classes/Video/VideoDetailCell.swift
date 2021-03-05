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

class VideoDetailCell: UICollectionViewCell, CellWithPhotoProtocol {
    static let reuseIdentifier = "VideoDetailCell"
    
    var playerView = PlayerView()

    var activityIndicator = UIActivityIndicatorView(style: .white)

    var imageView = UIImageView()

    var videoCache: VideoCache?
    
    var photo: PhotoProtocol? {
        didSet {
            activityIndicator.isHidden = true
            if let photo = self.photo {
                if let image = photo.image {
                    display(image: image)
                } else if let asset = photo.asset {
                    display(asset: asset, targetSize: photo.targetSize ?? bounds.size)
                } else if let url = photo.url {
                    display(url: url)
                } else {
                    displayImageFailure()
                }
            }
        }
    }

    var image: UIImage? {
        return imageView.image ?? Asset.coverPlaceholder.image
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        contentView.backgroundColor = .white
        contentView.addSubview(imageView)
        contentView.addSubview(playerView)
        playerView.layer.contentsGravity = .resizeAspectFill

        contentView.addSubview(activityIndicator)

        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit

        setupActivityIndicator()

        videoCache = VideoCache.shared
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapVideoCell(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapVideoCell(_:)))
        tap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        contentView.addGestureRecognizer(longPress)
        
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
        #if DEBUG
        print("video cell deinit ☠️☠️☠️")
        #endif
    }

    fileprivate func setupActivityIndicator() {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = contentView.center
        activityIndicator.isHidden = true
    }

    fileprivate func display(url: URL) {
        activityIndicator.startAnimating()
        if let videoCache = videoCache {
            videoCache.fetchFilePathWith(key: url) { [weak self] (result) in
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let filePath):
                    self?.generateThumnbnail(filePath)
                case .failure(let error):
                    self?.displayImageFailure()
                    #if DEBUG
                    print("❌ cache video error: \(error)")
                    #endif
                }
            }
        } else {
            generateThumnbnail(url)
        }
    }
    
    func generateThumnbnail(_ url: URL) {
        photo?.generateThumbnail(url, size: .zero) { (result) in
            self.activityIndicator.stopAnimating()
            switch result {
            case .success(let image):                
                self.display(image: image)
            case .failure(_):
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
                self?.photo?.storeImage(image)
                self?.display(image: image)
            } else {
                self?.displayImageFailure()
            }
        }
    }

    fileprivate func displayImageFailure() {
        imageView.image = Asset.imageError.image
        imageView.contentMode = .center
        setNeedsDisplay()
    }

    fileprivate func displayErrorThumbnail() {
        imageView.image = Asset.browserErrorLoading.image
        imageView.contentMode = .center
        setNeedsDisplay()
    }

    @objc func tapVideoCell(_ gesture: UITapGestureRecognizer) {
        routerEvent(name: ImageViewGestureEvent.singleTap.rawValue, userInfo: nil)
    }

    @objc func doubleTapVideoCell(_ gesture: UITapGestureRecognizer) {
        var info = [String: Any]()
        info["mediaType"] = kUTTypeVideo
        routerEvent(name: ImageViewGestureEvent.doubleTap.rawValue, userInfo: info)
    }

    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        routerEvent(name: ImageViewGestureEvent.longPress.rawValue, userInfo: nil)
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
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40),
            activityIndicator.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
