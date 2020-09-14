//
//  PhotosAuthority.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/14.
//

import Foundation
import MobileCoreServices

@objc public class PhotosAuthority: NSObject {

    @objc public static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    @objc public static func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }

    @objc public static func isRearCameraAvailable() -> Bool {
        return UIImagePickerController.isCameraDeviceAvailable(.rear)
    }

    @objc static public func doesCameraSupportTakingPhotos() -> Bool {
        let media = kUTTypeImage as String
        return PhotosAuthority.cameraSupportsMedia(media, sourceType: .camera)
    }

    @objc static public func canUserPickPhotosFromPhotoLibrary() -> Bool {
        let media = kUTTypeMovie as String
        return PhotosAuthority.cameraSupportsMedia(media, sourceType: .photoLibrary)
    }

    @objc public static func cameraSupportsMedia(_ paramMediaType: String, sourceType: UIImagePickerController.SourceType) -> Bool {
        guard !paramMediaType.isEmpty else {
            return false
        }

        guard let sources = UIImagePickerController.availableMediaTypes(for: sourceType) else { return false }
        return sources.contains(paramMediaType)
    }
}
