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

    func generateThumbnail(_ url: URL, size: CGSize, completion: @escaping ((UIImage?) -> Void))
}

/// Photo can be image, assert, or a media url.
public class Photo: PhotoProtocol {

    public var underlyingImage: UIImage?

    public var url: URL?

    public var asset: PHAsset?

    public var assetSize: CGSize?

    public var captionContent: String?
    public var captionSignature: String?

    public private(set) var resourceType: PhotoResourceType

    lazy var urlAssetQueue: DispatchQueue = {
        DispatchQueue(label: "com.variflight.urlAssetQueue")
    }()
    
    let videoTypes = ["mp4", "m4a", "mov"]

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
            // last chance to set the value. For example: http://client.gsup.sichuanair.com/file.php?70c1dafd4eaccb9a722ac3fcd8459cfc.jpg
            if let suffix = url.absoluteString.components(separatedBy: ".").last {
                return videoTypes.contains(suffix)
            } else {
                return false
            }                        
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

extension Photo {
    public func generateThumbnail(_ url: URL, size: CGSize = .zero, completion: @escaping ((UIImage?) -> Void)) {
        let cache = URLCache.shared
        let urlRequest = URLRequest(url: url)
        if let response = cache.cachedResponse(for: urlRequest), let image = UIImage(data: response.data) {
            completion(image)
            return
        }

        urlAssetQueue.async { // 1
            let asset = AVURLAsset(url: url) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.maximumSize = size
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 0, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let thumbImage = UIImage(cgImage: cgThumbImage) //7
                // cache
                if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                   let data = thumbImage.pngData() {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(cachedResponse, for: urlRequest)
                }
                DispatchQueue.main.async { //8
                    self.underlyingImage = thumbImage
                    completion(thumbImage) //9
                }
            } catch {
                print("video thumbnail generated error: \(error.localizedDescription)") //10
                DispatchQueue.main.async {
                    completion(nil) //11
                }
            }
        }
    }

    func clearThumbnail() {
        underlyingImage = nil
    }

    func clearAsset() {
        urlAssetQueue.async {
            self.asset = nil
        }
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
