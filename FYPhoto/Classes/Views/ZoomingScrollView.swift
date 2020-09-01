//
//  FYZoomingScrollView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import UIKit
import Photos
import UICircularProgressRing

enum ImageViewTap: String {
    case singleTap = "single_tap"
    case doubleTap = "doubel_tap"
}

class ZoomingScrollView: UIScrollView {

    var photo: PhotoProtocol! {
        didSet {
            imageView.image = "cover_placeholder".photoImage
            circularProgressView.isHidden = true
            if photo != nil {
                if let image = photo.underlyingImage {
                    displayImage(image)
                } else if let asset = photo.asset {
                    displayAsset(asset)
                } else if let url = photo.url {
                    display(url)
                } else {
                    displayImageFailure()
                }
            }
        }
    }

    var imageView = FYDetectingImageView()

    var circularProgressView = UICircularProgressRing()

    let settingOptions: PhotoPickerSettingsOptions

    var imageManager: PHCachingImageManager?

    init(frame: CGRect, settingOptions: PhotoPickerSettingsOptions = .default, imageManager: PHCachingImageManager? = nil) {
        self.settingOptions = settingOptions
        self.imageManager = imageManager
        super.init(frame: frame)
        setup()

    }

    func setup() {
//        backgroundColor = .clear
        imageView.delegate = self
        imageView.contentMode = .scaleAspectFit

        circularProgressView.outerRingColor = .gray
        circularProgressView.innerRingColor = .systemBlue
        circularProgressView.style = .ontop
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

    func displayAsset(_ asset: PHAsset) {
        let _imageManager: PHImageManager
        if self.imageManager != nil {
            _imageManager = self.imageManager!
        } else {
            _imageManager = PHImageManager.default()
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast

        _imageManager.requestImage(for: asset, targetSize: bounds.size, contentMode: PHImageContentMode.aspectFit, options: options) { [weak self] (image, info) in
            if let image = image {
                self?.photo.underlyingImage = image
            } else {
                self?.displayImageFailure()
            }
        }
    }

    func display(_ url: URL) {
        if url.isFileURL {
            self.photo.underlyingImage = loadLocalImage(url)
        } else {
            circularProgressView.value = 0
            loadWebImage(url, progress: { (progress) in
                DispatchQueue.main.async {
                    if self.circularProgressView.isHidden == true {
                        self.circularProgressView.isHidden = false
                    }
                    self.circularProgressView.value = CGFloat(progress)
                }

            }) { (image, error) in
                DispatchQueue.main.async {
                    self.circularProgressView.isHidden = true
                    if let image = image {
                        self.photo.underlyingImage = image
                    } else if error != nil {
                        self.displayImageFailure()
                    }
                }
            }
        }
    }

    func displayImageFailure() {
        imageView.image = "ImageError".photoImage
        imageView.contentMode = .center
        setNeedsDisplay()
    }
}

extension ZoomingScrollView: FYDetectingImageViewDelegate {
//    func handleImageViewSingleTap(_ touchPoint: CGPoint) {
//        routerEvent(name: ImageViewTap.singleTap.rawValue, userInfo: nil)
//    }

    func handleImageViewDoubleTap(_ touchPoint: CGPoint) {
        routerEvent(name: ImageViewTap.doubleTap.rawValue, userInfo: ["touchPoint": touchPoint])
    }

}

//extension ZoomingScrollView: UICircularProgressRingDelegate {
//    func didFinishProgress(for ring: UICircularProgressRing) {
//        <#code#>
//    }
//
//    func didPauseProgress(for ring: UICircularProgressRing) {
//        <#code#>
//    }
//
//    func didContinueProgress(for ring: UICircularProgressRing) {
//        <#code#>
//    }
//
//    func didUpdateProgressValue(for ring: UICircularProgressRing, to newValue: CGFloat) {
//        <#code#>
//    }
//
//    func willDisplayLabel(for ring: UICircularProgressRing, _ label: UILabel) {
//        <#code#>
//    }
//
//
//}
