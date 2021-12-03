//
//  SelectedImage.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/30.
//

import Foundation
import Photos
import UIKit

public class SelectedImage {
    public init(asset: PHAsset?, image: UIImage) {
        self.asset = asset
        self.image = image
    }

    public let asset: PHAsset?
    public let image: UIImage

    public lazy var data: Data? = {
        var _data: Data?
        if let asset = asset {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true

            PHImageManager.default().requestImageData(for: asset, options: options) { (data, _, _, _) in
                 _data = data
            }
            return _data
        } else {
            return image.pngData()
        }
    }()
}
