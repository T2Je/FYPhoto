//
//  PhotosAuthority.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/14.
//

import Foundation
import MobileCoreServices
import Photos
import UIKit

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

    static func requestPhotoAuthority(_ completion: @escaping (_ isSuccess: Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        completion(true)
                    case .denied, .restricted, .notDetermined:
                        completion(false)
                        print("⚠️ without authorization! ⚠️")
                    @unknown default:
                        fatalError()
                    }
                }
            }
        default:
            completion(false)
        }
    }

    @available(iOS 14, *)
    static func presentLimitedLibraryPicker(title: String, message: String?, from viewController: UIViewController) {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            return
        }
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: L10n.selectMorePhotos, style: .default, handler: { (_) in
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
        }))
        alert.addAction(UIAlertAction.init(title: L10n.keepCurrent, style: .default))
        viewController.present(alert, animated: true, completion: nil)
    }
}
