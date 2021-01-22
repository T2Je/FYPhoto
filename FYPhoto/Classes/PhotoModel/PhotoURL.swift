//
//  PhotoURL.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/10.
//

import Foundation
import Photos

class PhotoURL: PhotoProtocol {
    func isEqualTo(_ photo: PhotoProtocol) -> Bool {
        guard let photoUrl = photo.url else {
            return false
        }
        return photoUrl == url!
    }
    
    private(set) var image: UIImage?
    var metaData: Data?
    
    var url: URL?
    
//    var _cached: URL?
//    
//    var cachedURL: URL? {
//        return _cached
//    }
    
    var asset: PHAsset?
    var targetSize: CGSize?
    
    private(set) var captionContent: String?
    private(set) var captionSignature: String?
    
    private lazy var urlAssetQueue: DispatchQueue = DispatchQueue(label: "com.variflight.urlAssetQueue")
    private let videoTypes = ["mp4", "m4a", "mov"]
    
    var isVideo: Bool {
        guard let url = url else { return false }
        
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
    }
    
    init(url: URL) {
        self.url = url
    }
    
    static func == (lhs: PhotoURL, rhs: PhotoURL) -> Bool {
        lhs.url! == rhs.url!
    }
    
    func storeImage(_ image: UIImage) {
        self.image = image
    }
    
    // TODO: 😴zZ Use method in URL+Thumbnail instead
    func generateThumbnail(_ url: URL, size: CGSize, completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        url.generateThumbnail { (result) in
            completion(result)
        }
    }
    
    func clearThumbnail() {
        image = nil
        guard let url = url else {
            return
        }
        let cache = URLCache.shared
        let urlRequest = URLRequest(url: url)
        cache.removeCachedResponse(for: urlRequest)
    }

    func clearAsset() {
        urlAssetQueue.async {
            self.asset = nil
            self.image = nil
        }
    }
    
    func setCaptionContent(_ content: String) {
        self.captionContent = content
    }
    
    func setCaptionSignature(_ signature: String) {
        self.captionSignature = signature
    }
    
}
