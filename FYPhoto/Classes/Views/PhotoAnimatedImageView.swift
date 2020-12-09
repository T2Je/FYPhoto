//
//  FYDetectingImageView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import UIKit
import Photos
import SDWebImage

protocol DetectingTapViewDelegate: class {
    func handleSingleTap(_ touchPoint: CGPoint)
    func handleDoubleTap(_ touchPoint: CGPoint)
}


protocol DetectingTapView {
    var tapGestureDelegate: DetectingTapViewDelegate? { get set }
    var singleTap: UITapGestureRecognizer { get }
    var doubleTap: UITapGestureRecognizer { get}
}

class PhotoAnimatedImageView: SDAnimatedImageView, DetectingTapView {

    weak var tapGestureDelegate: DetectingTapViewDelegate?

    let singleTap: UITapGestureRecognizer
    let doubleTap: UITapGestureRecognizer
    override init(frame: CGRect = .zero) {

        doubleTap = UITapGestureRecognizer()
        doubleTap.numberOfTapsRequired = 2
        
        singleTap = UITapGestureRecognizer()
        singleTap.numberOfTapsRequired = 1

        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(doubleTap)
        
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)
        
        doubleTap.addTarget(self, action: #selector(doubleTap(_:)))
        singleTap.addTarget(self, action: #selector(singleTap(_:)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func singleTap(_ tap: UITapGestureRecognizer) {
        tapGestureDelegate?.handleSingleTap(tap.location(in: self))
    }

    @objc func doubleTap(_ tap: UITapGestureRecognizer) {
        tapGestureDelegate?.handleDoubleTap(tap.location(in: self))
    }
    
    func setAsset(_ asset: PHAsset, targeSize: CGSize, resultHandler: ((UIImage?) -> Void)? = nil) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        PHImageManager.default().requestImageData(for: asset, options: options) { (data, _, _, _) in
            if let data = data {
                let format = NSData.sd_imageFormat(forImageData: data)
                if format == .GIF {
                    if let animatedImage = SDAnimatedImage(data: data) {
                        self.image = animatedImage
                        resultHandler?(animatedImage)
                    }
                } else {
                    if let image = UIImage(data: data) {
                        self.image = image
                        resultHandler?(image)
                    }
                }
            } else {
                resultHandler?(nil)
            }
        }
    
//        PHImageManager.default().requestImage(for: asset, targetSize: targeSize, contentMode: .aspectFit, options: options) { (image, info) in
//
//            if let image = image {
//                if asset.playbackStyle == .imageAnimated {
//                    if let imageData = image.pngData(),
//                       let animatedImage = SDAnimatedImage(data: imageData) {
//                        self.image = animatedImage
//                        resultHandler?(animatedImage)
//                    }
//                } else {
//                    self.image = image
//                    resultHandler?(image)
//                }
//            } else {
//                resultHandler?(nil)
//            }
//        }
    }
    
    func setImage(url: URL, placeholder: UIImage?, contentMode: ContentMode = .scaleAspectFit, progress: ((Int, Int, URL?) -> Void)? = nil, completed: ((Result<UIImage, Error>) -> Void)? = nil) {
        self.contentMode = contentMode
        if url.isFileURL {
            do {
                let data = try Data(contentsOf: url)
                let format = NSData.sd_imageFormat(forImageData: data)
                if format == .GIF {
                    if let animatedImage = SDAnimatedImage(data: data) {
                        image = animatedImage
                        completed?(.success(animatedImage))
                    }
                } else {
                    if let image = UIImage(data: data) {
                        self.image = image
                        completed?(.success(image))
                    }
                }
            } catch {
                completed?(.failure(error))
            }
        } else {
            sd_setImage(with: url, placeholderImage: placeholder, progress: progress) { (image, error, cacheType, url) in
                if let error = error {
                    completed?(.failure(error))
                } else if let image = image {
                    completed?(.success(image))
                }
            }
        }
        
    }
}
