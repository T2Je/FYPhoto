//
//  UIImagePickerController+Tool.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation
import MobileCoreServices
import Photos
import UIKit

public extension UIImagePickerController {
    @objc func fg_pickerFinished(withInfo info: [UIImagePickerController.InfoKey: Any]) -> UIImage? {
        guard let type = info[.mediaType] as? String else { return nil }
        guard type == (kUTTypeImage as String) else { return nil }

        guard let _image: UIImage = info[.originalImage] as? UIImage  else { return nil }
        var image: UIImage!
        image = _image

        if #available(iOS 11, *) {
            if let asset = info[.phAsset] as? PHAsset {
                let options = PHImageRequestOptions()
                options.resizeMode = .exact
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = true
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { (_image, _) in
                     image = _image
                }
            }
        }

        if image.imageOrientation != .up {
            // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
            // 以下为调整图片角度的部分
            UIGraphicsBeginImageContext(image.size)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        if sourceType == .camera {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(fg_image(_:didFinishSavingWithError:contextInfo:)), nil)
        }

        return image
    }

    @objc func fg_image(_ image: UIImage, didFinishSavingWithError error: Error, contextInfo: UnsafeMutableRawPointer) {
        print("photo saved")
    }
}
