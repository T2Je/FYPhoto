//
//  PhotoPickerViewController+CameraDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/8.
//

import Foundation
import MobileCoreServices
import Photos

extension PhotoPickerViewController: CameraViewControllerDelegate {
    public func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey : Any]) {
        guard let mediaType = info[.mediaType] as? String else { return }

        switch mediaType {
//        case "public.image":
        case String(kUTTypeImage):
            guard let data = info[.mediaMetadata] as? Data else { return }
            
            var asset: PHAsset?
            
            CameraViewController.saveImageDataToAlbums(data) { (error) in
                if let error = error {
                    print("🤢\(error)🤮")
                } else {
                    print("image saved")
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let result = PHAsset.fetchAssets(with: fetchOptions)
                    asset = result.firstObject
                }
            }
            cameraViewController.dismiss(animated: true) {
                guard let image = info[.originalImage] as? UIImage else { return }
                if let asset = asset {
                    self.selectedPhotos?([SelectedImage(asset: asset, image: image)])
                }
                self.dismiss(animated: true, completion: nil)                
            }
        case String(kUTTypeMovie):
            guard let videoURL = info[.mediaURL] as? URL else {
                cameraViewController.dismiss(animated: true, completion: nil)
                return
            }

            cameraViewController.dismiss(animated: true) {
//                 Editor controller
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
        print("video path: \(path)\npath.path: \(path.path)")
        CameraViewController.saveVideoDataToAlbums(path) { [weak self] (error) in
            DispatchQueue.main.async {
                preview.dismiss(animated: true, completion: {
                    if let error = error {
                        print("❌ \(error)")
                    } else {
                        guard let videoAsset = PhotoPickerResource.shared.allVideos().firstObject else { return }
                        let highQualityImage = videoAsset.getHightQualityImageSynchorously()
                        let thumbnail = videoAsset.getThumbnailImageSynchorously()
                        let selectedVideo = SelectedVideo(asset: videoAsset, fullImage: highQualityImage, url: path)
                        selectedVideo.briefImage = thumbnail
                        self?.selectedVideo?(.success(selectedVideo))
                        self?.dismiss(animated: true, completion: nil)
                        print("video saved successfully")
                    }
                })
            }            
        }        
    }
    
    public func videoPreviewControllerDidCancel(_ preview: VideoPreviewController) {
        preview.dismiss(animated: true, completion: nil)
    }
}
