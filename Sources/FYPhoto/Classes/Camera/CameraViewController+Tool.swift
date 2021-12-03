//
//  CameraViewController+Tool.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/24.
//

import Foundation
import Photos
import UIKit

public extension CameraViewController {
    static func saveImageDataToAlbums(_ photoData: Data, completion: @escaping ((Result<Void, Error>) -> Void)) {
        SaveMediaTool.saveImageDataToAlbums(photoData, completion: completion)
    }

    static func saveImageToAlbums(_ image: UIImage, completion: @escaping ((Result<Void, Error>) -> Void)) {
        SaveMediaTool.saveImageToAlbums(image, completion: completion)
    }

    static func saveVideoDataToAlbums(_ videoPath: URL, completion: @escaping ((Result<Void, Error>) -> Void)) {
        SaveMediaTool.saveVideoDataToAlbums(videoPath, completion: completion)
    }
}
