//
//  FYPhoto.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation
import Photos

public protocol Asset {
    var asset: PHAsset? { get set }
    var assetSize: CGSize? { get set }
}

public protocol PhotoProtocol: Asset {
    var underlyingImage: UIImage? { get set }
    var url: URL? { get set }

    var index: Int { get set }

    var isVideo: Bool { get }

    var captionContent: String? { get set }
    var captionSignature: String? { get set }
}

public class Photo: PhotoProtocol, Equatable {
    public var captionContent: String?

    public var captionSignature: String?

    public static func == (lhs: Photo, rhs: Photo) -> Bool {
        if let lhsAsset = lhs.asset, let rhsAsset = rhs.asset {
            return lhsAsset.localIdentifier == rhsAsset.localIdentifier
        }
        if let lhsURL = lhs.url, let rhsURL = rhs.url {
            return lhsURL == rhsURL
        }
        return lhs.index == rhs.index
    }

    public var underlyingImage: UIImage?

    public var url: URL?

    public var asset: PHAsset?

    public var assetSize: CGSize?

    public var index: Int = 0

    public var isVideo: Bool {
        if let asset = asset {
            return asset.mediaType == .video
        } else {
            return false
        }
    }

    init() {

    }

    convenience public init(image: UIImage, index: Int = 0) {
        self.init()
        self.underlyingImage = image
        self.index = index
    }

    convenience public init(url: URL) {
        self.init()
        self.url = url
    }

    convenience public init(asset: PHAsset) {
        self.init()
        self.asset = asset
    }
}
