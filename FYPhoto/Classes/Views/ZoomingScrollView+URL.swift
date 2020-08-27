//
//  ZoomingScrollView+URL.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/3.
//

import Foundation
import SDWebImage

extension ZoomingScrollView {
    func loadLocalImage(_ url: URL) -> UIImage? {
        return UIImage(contentsOfFile: url.path)
    }

    func loadWebImage(_ url: URL, progress: @escaping ((_ progress: Float) -> Void), completion: @escaping ((UIImage?, Error?) -> Void)) {
        SDWebImageManager.shared.loadImage(with: url, options: .continueInBackground, progress: { (recieved, expected, url) in
            let _progress = Float(recieved) / Float(expected)
            print("recieved: \(recieved), expected: \(expected)")
            if expected > 0 {
                progress(_progress)
            }
        }) { (image, data, error, cacheType, finished, _) in
            completion(image, error)
        }
    }
}
