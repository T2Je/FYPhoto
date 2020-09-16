//
//  URL+ImageVideoChecker.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/16.
//

import Foundation
import MobileCoreServices
import AVFoundation

extension URL {
    func isImage() -> Bool {
        guard !pathExtension.isEmpty else {
            return false
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil) else {
            return false
        }

        return UTTypeConformsTo(uti.takeRetainedValue(), kUTTypeImage)
    }

    func isVideo() -> Bool {
        guard !pathExtension.isEmpty else {
            return false
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil) else {
            return false
        }
        
        return UTTypeConformsTo(uti.takeRetainedValue(), kUTTypeMovie)
    }


}

extension URL {
    func thumbnail(_ completion: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.global().async { //1
            let asset = AVAsset(url: self) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let thumbImage = UIImage(cgImage: cgThumbImage) //7
                DispatchQueue.main.async { //8
                    completion(thumbImage) //9
                }
            } catch {
                print(error.localizedDescription) //10
                DispatchQueue.main.async {
                    completion(nil) //11
                }
            }
        }
    }
}
