//
//  CameraViewController+Tool.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/24.
//

import Foundation
import Photos

public extension CameraViewController {
    static func saveImageDataToAlbums(_ photoData: Data, completion: ((Error?) -> Void)) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
//                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)

//                    if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
//                        let livePhotoCompanionMovieFileOptions = PHAssetResourceCreationOptions()
//                        livePhotoCompanionMovieFileOptions.shouldMoveFile = true
//                        creationRequest.addResource(with: .pairedVideo,
//                                                    fileURL: livePhotoCompanionMovieURL,
//                                                    options: livePhotoCompanionMovieFileOptions)
//                    }
//
//                    // Save Portrait Effects Matte to Photos Library only if it was generated
//                    if let portraitEffectsMatteData = self.portraitEffectsMatteData {
//                        let creationRequest = PHAssetCreationRequest.forAsset()
//                        creationRequest.addResource(with: .photo,
//                                                    data: portraitEffectsMatteData,
//                                                    options: nil)
//                    }
//                    // Save Portrait Effects Matte to Photos Library only if it was generated
//                    for semanticSegmentationMatteData in self.semanticSegmentationMatteDataArray {
//                        let creationRequest = PHAssetCreationRequest.forAsset()
//                        creationRequest.addResource(with: .photo,
//                                                    data: semanticSegmentationMatteData,
//                                                    options: nil)
//                    }

                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    completion(error)
                }

                )
            } else {
                completion()
            }
        }
    }
    static func saveVideoDataToAlbums(_ videoPath: URL, _ completionTarget: Any?, _ completionSelector: Selector?) {

    }
}
