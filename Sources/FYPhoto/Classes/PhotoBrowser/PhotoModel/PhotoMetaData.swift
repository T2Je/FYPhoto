//
//  PhotoMetaData.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/10.
//

import Foundation
import Photos
import SDWebImage

class PhotoMetaData: PhotoProtocol {
//    let resourceType: PhotoResourceType

    var url: URL?

    var asset: PHAsset?
    var targetSize: CGSize?

    var image: UIImage?
    var metaData: Data?

    var isVideo: Bool {
        // FIXME: How do I get this value from data 🤔?
        return false
    }

    var restoreData: CroppedRestoreData?

    init(data: Data) {
        self.metaData = data
    }

    func storeImage(_ image: UIImage?) {
        self.image = image
    }

    func isEqualTo(_ photo: PhotoProtocol) -> Bool {
        guard let data = metaData else { return false }
        return data == metaData!
    }
}
