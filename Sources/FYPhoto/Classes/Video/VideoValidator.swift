//
//  VideoValidator.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/24.
//

import Foundation
import Photos

protocol VideoValidatorProtocol {
    func validVideoDuration(_ asset: PHAsset, limit: Double) -> Bool
    func validVideoSize(_ url: URL, limit: Double) -> Bool
}

class FYVideoValidator: VideoValidatorProtocol {
    /// Validate the video asset's duration is within the time limit.
    /// - Parameters:
    ///   - asset: selected asset
    ///   - limit: time limit
    /// - Returns: Bool value
    func validVideoDuration(_ asset: PHAsset, limit: Double) -> Bool {
        if limit <= 0 {
            return true
        } else {
            return asset.duration <= limit
        }
    }

    /// Validate the asset's memory footprint is within the limit.
    /// - Parameters:
    ///   - asset: selected video asset url
    ///   - limit: memory footprint limit
    /// - Returns: Bool value
    func validVideoSize(_ url: URL, limit: Double) -> Bool {
        guard url.isFileURL else {
            return false
        }
        return url.sizePerMB() <= limit
    }
}
