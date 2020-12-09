//
//  FYZoomingScrollView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import UIKit
import Photos
import UICircularProgressRing
import MobileCoreServices

enum ImageViewTap: String {
    case singleTap = "single_tap"
    case doubleTap = "doubel_tap"
}

class ZoomingScrollView: UIScrollView {
    var photo: PhotoProtocol! {
        didSet {
            circularProgressView.isHidden = true
            if photo != nil {
                if let image = photo.underlyingImage {
                    displayImage(image)
                } else if let asset = photo.asset {
                    displayAsset(asset, targetSize: photo.assetSize ?? bounds.size)
                } else if let url = photo.url {
                    display(url)
                } else {
                    displayImageFailure()
                }
            }
        }
    }

    var imageView = PhotoAnimatedImageView()

    var circularProgressView = UICircularProgressRing()

    let settingOptions: PhotoPickerSettingsOptions

    init(frame: CGRect, settingOptions: PhotoPickerSettingsOptions = .default) {
        self.settingOptions = settingOptions
        super.init(frame: frame)
        setup()
    }

    func setup() {
//        backgroundColor = .clear
        imageView.tapGestureDelegate = self
        imageView.contentMode = .scaleAspectFit

        circularProgressView.outerRingColor = .gray
        circularProgressView.innerRingColor = .orange
        circularProgressView.style = .ontop
        circularProgressView.startAngle = 270
        circularProgressView.isHidden = true
        circularProgressView.minValue = 0
        circularProgressView.maxValue = 1
        circularProgressView.innerRingWidth = 3

        addSubview(imageView)
        addSubview(circularProgressView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])


        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circularProgressView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circularProgressView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            circularProgressView.widthAnchor.constraint(equalToConstant: 130),
            circularProgressView.heightAnchor.constraint(equalToConstant: 130)
        ])

        showsHorizontalScrollIndicator = settingOptions.contains(.displayHorizontalScrollIndicator)
        showsVerticalScrollIndicator = settingOptions.contains(.displayVerticalScrollIndicator)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func displayImage(_ image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        setNeedsDisplay()
    }

    func displayAsset(_ asset: PHAsset, targetSize: CGSize) {
        imageView.setAsset(asset, targeSize: targetSize) { [weak self] (image) in
            if let image = image {
                self?.photo.underlyingImage = image
            } else {
                self?.displayImageFailure()
            }
        }
    }

    func display(_ url: URL, placeholder: UIImage? = nil) {
        circularProgressView.value = 0
        imageView.setImage(url: url, placeholder: placeholder) { (recieved, expected, _) in
            let progress = recieved / expected
            DispatchQueue.main.async {
                if self.circularProgressView.isHidden == true {
                    self.circularProgressView.isHidden = false
                }
                self.circularProgressView.value = CGFloat(progress)
            }
        } completed: { [weak self] (result) in
            switch result {
            case .failure(let error):
                #if DEBUG
                print("❌ \(error) in ",  #file)
                #endif
                self?.displayImageFailure()
            case .success(let image):
                self?.photo.underlyingImage = image
            }
        }
    }

    func displayImageFailure() {
        imageView.image = "ImageError".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }
}

extension ZoomingScrollView: DetectingTapViewDelegate {
    func handleSingleTap(_ touchPoint: CGPoint) {
        routerEvent(name: ImageViewTap.singleTap.rawValue, userInfo: nil)
    }
    
    func handleDoubleTap(_ touchPoint: CGPoint) {
        var info = [String: Any]()
        info["touchPoint"] = touchPoint
        info["mediaType"] = kUTTypeImage
        routerEvent(name: ImageViewTap.doubleTap.rawValue, userInfo: info)
    }
}
