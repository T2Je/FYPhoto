//
//  SelectedVideo.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation
import Photos

@objc(VideoModel)
public class SelectedVideo: NSObject {

    public var asset: PHAsset
    public var briefImage: UIImage?
    public var fullImage: UIImage?
    public var url: URL

    public init(asset: PHAsset, fullImage: UIImage?, url: URL) {
        self.asset = asset
        self.fullImage = fullImage        
        self.url = url
        super.init()
    }
}
