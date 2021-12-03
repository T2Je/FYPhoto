//
//  URL+Thumbnail.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/14.
//

import Foundation
import AVFoundation
import UIKit

extension URL {

    public func generateThumbnail(maximumSize: CGSize = .zero, completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        let cache = URLCache.shared
        let urlRequest = URLRequest(url: self)
        if let response = cache.cachedResponse(for: urlRequest), let image = UIImage(data: response.data) {
            completion(.success(image))
            return
        }

        DispatchQueue.global().async { // 1
            let url = URL(string: absoluteString)
            let asset = AVURLAsset(url: url!) // 2

            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) // 3
            avAssetImageGenerator.maximumSize = maximumSize
            avAssetImageGenerator.appliesPreferredTrackTransform = true // 4
            let thumnailTime = CMTimeMake(value: 0, timescale: 1) // 5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) // 6
                let thumbImage = UIImage(cgImage: cgThumbImage) // 7
                // cache
                if let response = HTTPURLResponse(url: self, statusCode: 200, httpVersion: nil, headerFields: nil),
                   let data = thumbImage.pngData() {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(cachedResponse, for: urlRequest)
                }
                DispatchQueue.main.async { // 8
                    completion(.success(thumbImage)) // 9
                }
            } catch {
                print("video thumbnail generated error: \(error.localizedDescription)") // 10
                DispatchQueue.main.async {
                    completion(.failure(error)) // 11
                }
            }
        }
    }
}
