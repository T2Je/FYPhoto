//
//  FYPhotoPickerConfiguration.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/3.
//

import Foundation

/// A configuration for `FYPhoto.PickerViewController`.
public struct FYPhotoPickerConfiguration {
    /// Maximum number of assets that can be selected. Default is 1.
    ///
    /// Setting `selectionLimit` to 0 means maximum supported by the system.
    public var selectionLimit: Int = 1
    
    /// Filter the media types PhotoPickerController can display. Default are video and image.
    public var filterdMedia: MediaOptions = .all
    
    /// Maximum video duration can pick. Default is 15.
    public var maximumVideoDuration: Double = 15
    
    /// Maximum video size can pick. Default is 40 MB.
    public var maximumVideoMemorySize: Double = 40
    
    /// Video compressed quality. Default is 640x480.
    public var compressedQuality: VideoCompressor.QualityLevel = .AVAssetExportPreset640x480
    
    public init() {
        
    }
}
