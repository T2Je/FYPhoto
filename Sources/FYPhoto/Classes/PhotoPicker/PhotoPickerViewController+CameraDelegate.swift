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
                cameraViewController.dismiss(animated: true, completion: nil)
                return
            }

            cameraViewController.dismiss(animated: true) {
                let previewVC = VideoPreviewController(videoURL: videoURL)
                previewVC.delegate = self
                self.present(previewVC, animated: true, completion: nil)
            }
        default:
            break
        }
    }

    public func cameraDidCancel(_ cameraViewController: CameraViewController) {
        cameraViewController.dismiss(animated: true, completion: nil)
    }

}

extension PhotoPickerViewController: VideoPreviewControllerDelegate {
    public func videoPreviewController(_ preview: VideoPreviewController, didSaveVideoAt path: URL) {
        preview.delegate = nil
//        print("video path: \(path)\npath.path: \(path.path)")
        SaveMediaTool.saveVideoDataToAlbums(path) { result in
            DispatchQueue.main.async {
                preview.dismiss(animated: true, completion: {
                    switch result {
                    case .success(_):
                        print("video saved successfully")
                        self.showMessage("video saved successfully")
                        guard let videoAsset = PhotoPickerResource.shared.allVideos().firstObject else { return }
                        let thumbnail = videoAsset.getThumbnailImageSynchorously()
                        PHImageManager.default().requestAVAsset(forVideo: videoAsset, options: nil) { (avAsset, _, _) in
                            guard let urlAsset = avAsset as? AVURLAsset else { return }
                            DispatchQueue.main.async {
                                let selectedVideo = SelectedVideo(url: urlAsset.url)
                                selectedVideo.briefImage = thumbnail
                                self.selectedVideo?(.success(selectedVideo))
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    case .failure(let error):
                        self.showError(error)
                    }
                })
            }
        }
    }

    public func videoPreviewControllerDidCancel(_ preview: VideoPreviewController) {
        preview.dismiss(animated: true, completion: nil)
    }
}
