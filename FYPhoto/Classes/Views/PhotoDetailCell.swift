//
//  PhotoDetailCell.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos

class PhotoDetailCell: UICollectionViewCell {
    let zoomingView = ZoomingScrollView(frame: .zero, settingOptions: PhotoPickerSettingsOptions.default)
    var imageManager: PHCachingImageManager? {
        didSet {
            zoomingView.imageManager = imageManager
        }
    }

    var image: UIImage? {
        return zoomingView.imageView.image
    }

    var maximumZoomScale: CGFloat = 1 {
        willSet {
            zoomingView.maximumZoomScale = newValue
        }
    }

    var minimumZoomScale: CGFloat = 1 {
        willSet {
            zoomingView.minimumZoomScale = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomingView)
//        contentView.backgroundColor = .white
        zoomingView.delegate = self
        zoomingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            zoomingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPhoto(_ photo: PhotoProtocol) {
        zoomingView.photo = photo
    }

}

extension PhotoDetailCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingView.imageView
    }
}
