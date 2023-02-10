//
//  PhotoPickerViewController+CameraDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/8.
//

import Foundation
import MobileCoreServices
import Photos
import UIKit

extension PhotoPickerViewController: CameraViewControllerDelegate {
    public func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey: Any]) {
        self.willDismiss = true
        guard let mediaType = info[.mediaType] as? String else {
            cameraViewController.dismiss(animated: true, completion: nil)
            return
        }
        switch mediaType {
        case String(kUTTypeImage):
            guard let data = info[.mediaMetadata] as? Data else { return }

            cameraViewController.dismiss(animated: true) {

                SaveMediaTool.saveImageDataToAlbums(data) { (result) in
                    var asset: PHAsset?
                    switch result {
                    case .success(_):
                        print("image saved")
                        self.showMessage("image saved")
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                        let result = PHAsset.fetchAssets(with: fetchOptions)
                        asset = result.firstObject
                    case .failure(let error):
                        self.showError(error)
                    }

                    self.dismiss(animated: false) {
                        guard let image = info[.originalImage] as? UIImage else { return }
                        self.selectedPhotos?([SelectedImage(asset: asset, image: image)])
                    }
                }
            }
        case String(kUTTypeMovie):
            guard let videoURL = info[.mediaURL] as? URL else {
                cameraViewController.dismiss(animated: true) {
                    self.selectedVideo?(.failure(PhotoPickerError.DataNotFound))
                }
                return
            }
            
            cameraViewController.dismiss(animated: true) {
                self.selectedVideo?(.success(SelectedVideo(url: videoURL)))
            }
        default:
            break
        }
    }

    public func cameraDidCancel(_ cameraViewController: CameraViewController) {
        cameraViewController.dismiss(animated: true, completion: nil)
    }
}
