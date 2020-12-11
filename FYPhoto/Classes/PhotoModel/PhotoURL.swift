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
    
    var asset: PHAsset?
    var targetSize: CGSize?
    
    private(set) var captionContent: String?
    private(set) var captionSignature: String?
    
//    let resourceType: PhotoResourceType
    
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
//        resourceType = .url
    }
    
    static func == (lhs: PhotoURL, rhs: PhotoURL) -> Bool {
        lhs.url! == rhs.url!
    }
    
    func storeImage(_ image: UIImage) {
        self.image = image
    }
    
    func generateThumbnail(_ url: URL, size: CGSize, completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        let cache = URLCache.shared
        let urlRequest = URLRequest(url: url)
        if let response = cache.cachedResponse(for: urlRequest), let image = UIImage(data: response.data) {
            completion(.success(image))
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
                    self.image = thumbImage
                    completion(.success(thumbImage)) //9
                }
            } catch {
                print("video thumbnail generated error: \(error.localizedDescription)") //10
                DispatchQueue.main.async {
                    completion(.failure(error)) //11
                }
            }
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
        }
    }
    
    func setCaptionContent(_ content: String) {
        self.captionContent = content
    }
    
    func setCaptionSignature(_ signature: String) {
        self.captionSignature = signature
    }
    
}
