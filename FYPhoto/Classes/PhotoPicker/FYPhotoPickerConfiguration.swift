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
    
    /// Captured movie path extension
    public var moviePathExtension: String = "mp4"
        
    public var supportCamera: Bool = true

    public var uiConfiguration = FYUIConfiguration()
    
    public init() {
        
    }
}



public class FYUIConfiguration {
    public class BarColorSytle {

        public let itemTintColor: UIColor
        public let itemBackgroundColor: UIColor
        // bar backgroundColor
        public let backgroundColor: UIColor

        public init(itemTintColor: UIColor,
                    itemBackgroundColor: UIColor,
                    backgroundColor: UIColor) {
            self.itemTintColor = itemTintColor
            self.itemBackgroundColor = itemBackgroundColor
            self.backgroundColor = backgroundColor
        }
    }

    public init() {}

    public var topBarColorStyle = BarColorSytle(itemTintColor: UIColor(red: 24/255.0,
                                                                green: 135/255.0,
                                                                blue: 251/255.0,
                                                                alpha: 1),
                                         itemBackgroundColor: .white,
                                         backgroundColor: .white)


    public var pickerBottomBarColorStyle =
        BarColorSytle(itemTintColor: UIColor(red: 24/255.0,
                                             green: 135/255.0,
                                             blue: 251/255.0,
                                             alpha: 1),
                      itemBackgroundColor: UIColor(red: 249/255.0,
                                                   green: 249/255.0,
                                                   blue: 249/255.0,
                                                   alpha: 1),
                      backgroundColor: UIColor(red: 249/255.0,
                                               green: 249/255.0,
                                               blue: 249/255.0,
                                               alpha: 1))

    public var browserBottomBarColorStyle =
        BarColorSytle(itemTintColor: UIColor(red: 24/255.0,
                                             green: 135/255.0,
                                             blue: 251/255.0,
                                             alpha: 1),
                      itemBackgroundColor: .white,
                      backgroundColor: UIColor(white: 0.1, alpha: 0.9))
}
