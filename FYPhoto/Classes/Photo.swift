//
//  FYPhoto.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation
import Photos

public enum PhotoResourceType {
    case justImage
    case asset
    case url
    case none
}

public protocol Asset {
    var asset: PHAsset? { get set }
    var assetSize: CGSize? { get set }
}

public protocol PhotoProtocol: Asset {
    var underlyingImage: UIImage? { get set }
    var url: URL? { get set }

    var isVideo: Bool { get }

    var captionContent: String? { get set }
    var captionSignature: String? { get set }

    var resourceType: PhotoResourceType { get }
}

public class Photo: PhotoProtocol {

    public var underlyingImage: UIImage?

    public var url: URL?

    public var asset: PHAsset?

    public var assetSize: CGSize?

    public var captionContent: String?
    public var captionSignature: String?

    public private(set) var resourceType: PhotoResourceType

    public var isVideo: Bool {
        if let asset = asset {
            return asset.mediaType == .video
        } else if let url = url {
            if url.isImage() {
                return false
            }
            if url.isVideo() {
                return true
            }
            return false
        } else {
            return false
        }
    }

    private init() {
        resourceType = .none
    }

    convenience public init(image: UIImage) {
        self.init()
        self.underlyingImage = image
        resourceType = .justImage
    }

    convenience public init(url: URL) {
        self.init()
        self.url = url
        resourceType = .url
    }

    convenience public init(asset: PHAsset) {
        self.init()
        self.asset = asset
        resourceType = .asset
    }

}


extension Photo: Equatable {
    public static func == (lhs: Photo, rhs: Photo) -> Bool {
        if let lhsAsset = lhs.asset, let rhsAsset = rhs.asset {
            return lhsAsset.localIdentifier == rhsAsset.localIdentifier
        }
        if let lhsURL = lhs.url, let rhsURL = rhs.url {
            return lhsURL == rhsURL
        }
        return lhs.underlyingImage == rhs.underlyingImage
    }
}
