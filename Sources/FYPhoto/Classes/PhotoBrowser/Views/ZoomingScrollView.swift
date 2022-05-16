//
//  FYZoomingScrollView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import UIKit
import Photos
import MobileCoreServices

enum ImageViewGestureEvent: String {
    case singleTap = "single_tap"
    case doubleTap = "double_tap"
    case longPress = "long_press"
}

class ZoomingScrollView: UIScrollView {
    var photo: PhotoProtocol? {
        didSet {
            activityIndicator.isHidden = true
            if let photo = photo {
                if let image = photo.image {
                    displayImage(image)
                } else if let url = photo.url {
                    display(url, placeholder: photo.image)
                } else if let asset = photo.asset {
                    displayAsset(asset, targetSize: photo.targetSize ?? bounds.size)
                } else {
                    displayImageFailure()
                }
            }
        }
    }

    var imageView = PhotoAnimatedImageView()

    lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let activity = UIActivityIndicatorView(style: .large)
            activity.color = .white
            return activity
        } else {
            let activity = UIActivityIndicatorView(style: .whiteLarge)
            activity.color = .white
            return activity
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    func setup() {
        imageView.gestureDelegate = self
        imageView.contentMode = .scaleAspectFit

        addSubview(imageView)
        addSubview(activityIndicator)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func displayImage(_ image: UIImage) {
        imageView.image = nil
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        setNeedsDisplay()
    }

    func displayAsset(_ asset: PHAsset, targetSize: CGSize) {
        imageView.setAsset(asset, targeSize: targetSize) { [weak self] (image) in
            if image == nil {
                self?.displayImageFailure()
            }
        }
    }

    func display(_ url: URL, placeholder: UIImage? = nil) {
        if activityIndicator.isHidden {
            activityIndicator.isHidden = false
        }
        activityIndicator.startAnimating()
        imageView.setImage(url: url, placeholder: placeholder) { (recieved, expected, _) in
            let progress = CGFloat(recieved) / CGFloat(expected)
            print("image download progress: \(CGFloat(progress * 100))")
        } completed: { [weak self] (result) in
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.isHidden = true
            switch result {
            case .failure(let error):
                #if DEBUG
                print("❌ \(error) in ", #file)
                #endif
                self?.displayImageFailure()
            case .success(let image):
                self?.photo?.storeImage(image)
                self?.displayImage(image)
            }
        }
    }

    func displayImageFailure() {
        imageView.image = Asset.imageError.image
        imageView.contentMode = .center
        setNeedsDisplay()
    }
}

extension ZoomingScrollView: DetectingGestureViewDelegate {
    func handleSingleTap(_ touchPoint: CGPoint) {
        routerEvent(name: ImageViewGestureEvent.singleTap.rawValue, userInfo: nil)
    }

    func handleDoubleTap(_ touchPoint: CGPoint) {
        var info = [String: Any]()
        info["touchPoint"] = touchPoint
        info["mediaType"] = kUTTypeImage
        routerEvent(name: ImageViewGestureEvent.doubleTap.rawValue, userInfo: info)
    }

    func handleLongPress(_ touchPoint: CGPoint) {
        routerEvent(name: ImageViewGestureEvent.longPress.rawValue, userInfo: ["touchPoint": touchPoint])
    }
}
