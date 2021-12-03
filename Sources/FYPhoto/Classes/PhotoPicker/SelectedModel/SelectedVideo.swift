//
//  SelectedVideo.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation
import Photos
import UIKit

@objc(VideoModel)
public class SelectedVideo: NSObject {

    @available(iOS, deprecated: 0.3, message: "PHPickerViewController results can only load video urls from PhotoLibrary, use url instead")
    public var asset: PHAsset?

    public var briefImage: UIImage?

    @available(iOS, deprecated: 0.3, message: "High quality image of video is useless, use briefImage instead!")
    public var fullImage: UIImage?

    public var url: URL

    @available(iOS, deprecated: 0.3, message: "use init(url: URL) instead")
    public init(asset: PHAsset?, fullImage: UIImage?, url: URL) {
        self.asset = asset
        self.fullImage = fullImage
        self.url = url
        super.init()
    }

    public init(url: URL) {
        self.url = url
        super.init()
    }
}
