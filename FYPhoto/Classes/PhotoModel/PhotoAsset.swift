//
//  PhotoAsset.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/10.
//

import Foundation
import Photos

class PhotoAsset: PhotoProtocol {
    var image: UIImage?
    
    var metaData: Data?
    
    var url: URL?
    
    var asset: PHAsset?
    var targetSize: CGSize?
    
    let resourceType: PhotoResourceType
    
    var isVideo: Bool {
        guard let asset = asset else { return false }
        return asset.mediaType == .video
    }    
    
    func storeImage(_ image: UIImage) {
        self.image = image
    }
    
    init(asset: PHAsset) {
        self.asset = asset
        self.resourceType = .asset
    }
    
    func isEqualTo(_ photo: PhotoProtocol) -> Bool {
        guard let photoAsset = photo.asset else { return false }
        return photoAsset.localIdentifier == asset!.localIdentifier
    }    
}
