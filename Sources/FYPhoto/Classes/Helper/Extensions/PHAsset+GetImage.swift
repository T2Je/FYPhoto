//
//  PHAsset+GetImage.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation
import Photos
import UIKit

extension PHAsset {
    func getHightQualityImageSynchorously() -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        let targetSize = CGSize(width: pixelWidth, height: pixelHeight)
        var temp: UIImage?
        PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
            temp = image
        }
        return temp
    }

    func getThumbnailImageSynchorously() -> UIImage? {
        // FIXME: Synchronous image requests are incompatible with fast delivery mode, changing delivery mode to high
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        let targetSize = CGSize(width: 50, height: 50)
        var temp: UIImage?
        PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
            temp = image
        }
        return temp
    }

}
