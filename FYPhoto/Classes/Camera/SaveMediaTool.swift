//
//  SaveMediaTool.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/20.
//

import Foundation
import Photos

class SaveMediaTool {
    enum SaveMediaError: Error, LocalizedError {
        public var errorDescription: String? {
            switch self {
            case .withoutAuthourity:
                return "NoPermissionToSave".photoTablelocalized
            }
        }

        case withoutAuthourity
    }
    
    static func saveImageDataToAlbums(_ photoData: Data, completion: @escaping ((Error?) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    completion(error)
                })
            } else {
                completion(SaveMediaError.withoutAuthourity)
            }
        }
    }

    static func saveImageToAlbums(_ image: UIImage, completion: @escaping ((Error?) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
//                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    if let data = image.jpegData(compressionQuality: 1) {
                        creationRequest.addResource(with: .photo, data: data, options: options)
                    }
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    completion(error)
                }

                )
            } else {
                completion(SaveMediaError.withoutAuthourity)
            }
        }
    }
    
    static func saveVideoDataToAlbums(_ videoPath: URL, completion: @escaping ((Error?) -> Void)) {
        // Check the authorization status.
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the movie file to the photo library and cleanup.
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: videoPath, options: options)
                }, completionHandler: { success, error in
                    if !success {
                        print("FYPhoto couldn't save the movie to your photo library: \(String(describing: error))")
                    }
                    DispatchQueue.main.async {
                        completion(error)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(SaveMediaError.withoutAuthourity)
                }
            }
        }
    }
    
    static func alertSaveMediaCompleted(_ title: String?, _ message: String? = nil, on viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "GotIt".photoTablelocalized, style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func alertAthorityError(_ error: Error, on viewController: UIViewController) {
        let alertController = UIAlertController(title: "FailedToSaveMedia".photoTablelocalized, message: error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "GotIt".photoTablelocalized, style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        viewController.present(alertController, animated: true, completion: nil)
    }
}
