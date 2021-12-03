//
//  PhotoBrowserThumbnailCollectionViewCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/15.
//

import UIKit
import Photos

class PBSelectedPhotosThumbnailCell: UICollectionViewCell {
    static let reuseIdentifier = "PBSelectedPhotosThumbnailCell"

    let imageView = UIImageView()
    var photo: PhotoProtocol? {
        willSet {
            guard let photo = newValue else { return }
            if let image = photo.image {
                if image != imageView.image {
                    imageView.image = image
                }
            } else if let asset = photo.asset {
                PHImageManager.default().requestImage(for: asset,
                                                      targetSize: photo.targetSize ?? bounds.size,
                                                      contentMode: .aspectFill,
                                                      options: nil) { (image, _) in
                    if let image = image {
                        self.imageView.image = image
                        photo.storeImage(image)
                    }
                }
            }
        }
    }

    var cellBorderColor: UIColor = UIColor.systemBlue

    var thumbnailIsSelected: Bool = false {
        willSet {
            if newValue {
                contentView.layer.borderColor = cellBorderColor.cgColor
                contentView.layer.borderWidth = 2
            } else {
                contentView.layer.borderColor = UIColor.clear.cgColor
                contentView.layer.borderWidth = 0
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        contentView.addSubview(imageView)
        imageView.frame = contentView.frame
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
