//
//  PhotoPickerViewController+CameraDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/8.
//

import Foundation
import MobileCoreServices

extension PhotoPickerViewController: CameraViewControllerDelegate {
    public func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey : Any]) {
        guard let mediaType = info[.mediaType] as? String else { return }

        switch mediaType {
//        case "public.image":
        case String(kUTTypeImage):
            guard let data = info[.mediaMetadata] as? Data else { return }
            CameraViewController.saveImageDataToAlbums(data) { (error) in
                if let error = error {
                    print("🤢\(error)🤮")
                } else {
                    print("image saved")
                }
            }
            cameraViewController.dismiss(animated: true) {
                guard let image = info[.originalImage] as? UIImage else { return }
                let photo = Photo(image: image)
                let detailVC = PhotoBrowserViewController(photos: [photo], initialIndex: 0)
                detailVC.delegate = self
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
        case String(kUTTypeMovie):
            guard
                let videoURL = info[.mediaURL] as? URL
                else {
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
        print(#function)
        preview.delegate = nil
        preview.dismiss(animated: true, completion: nil)
        print("video path: \(path)\npath.path: \(path.path)")
            
        CameraViewController.saveVideoDataToAlbums(path) { (error) in
            #if DEBUG
            if let error = error {
                print("❌ \(error)")
            } else {
                print("video saved successfully")
            }
            #endif
        }        
    }
    
    public func videoPreviewControllerDidCancel(_ preview: VideoPreviewController) {
        preview.dismiss(animated: true, completion: nil)
    }
    
    
}
