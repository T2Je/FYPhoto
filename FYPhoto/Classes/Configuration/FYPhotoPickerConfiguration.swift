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
    
    @available(swift, deprecated: 1.2.0, message: "use mediaFilter instead")
    public var filterdMedia: MediaOptions = .all
    
    /// Filter the media types PhotoPickerController can display. Default are video and image.
    public var mediaFilter: MediaOptions = .all
        
    /// Maximum video duration can pick. Default is 15.
    public var maximumVideoDuration: Double = 15
    
    /// Maximum video size can pick. No limit by default
    public var maximumVideoMemorySize: Double = 0
    
    /// Video compressed quality. Default is 640x480.
    public var compressedQuality: VideoCompressor.QualityLevel = .AVAssetExportPreset640x480
    
    /// Captured movie path extension
    public var moviePathExtension: String = "mp4"
    
    /// whether first cell is camera cell or not
    public var supportCamera: Bool = true

    @available(swift, deprecated: 1.2.0, message: "custom color with colorConfiguration")
    public var uiConfiguration = FYUIConfiguration()
    
    public var colorConfiguration = FYColorConfiguration()
    
    public init() {
        
    }
}

@available(swift, deprecated: 1.2.0, message: "Use FYColorConfiguration instead")
public class FYUIConfiguration {
    public class BarColorSytle {

        public let itemTintColor: UIColor
        public let itemDisableColor: UIColor
        public let itemBackgroundColor: UIColor
        // bar backgroundColor
        public let backgroundColor: UIColor

        public init(itemTintColor: UIColor,
                    itemDisableColor: UIColor,
                    itemBackgroundColor: UIColor,
                    backgroundColor: UIColor) {
            self.itemTintColor = itemTintColor
            self.itemDisableColor = itemDisableColor
            self.itemBackgroundColor = itemBackgroundColor
            self.backgroundColor = backgroundColor
        }
    }

    public init() {}

    public var selectionTitleColor: UIColor = .white
    public var selectionBackgroudColor: UIColor = .fyBlueTintColor

    public var topBarColorStyle =
        BarColorSytle(itemTintColor: UIColor.fyBlueTintColor,
                      itemDisableColor: .systemGray,
                      itemBackgroundColor: .white,
                      backgroundColor: .white)


    public var pickerBottomBarColorStyle =
        BarColorSytle(itemTintColor: UIColor.fyBlueTintColor,
                      itemDisableColor: .fyItemDisableColor,
                      itemBackgroundColor: .fyGrayBackgroundColor,
                      backgroundColor: .fyGrayBackgroundColor)

    public var browserBottomBarColorStyle =
        BarColorSytle(itemTintColor: UIColor.fyBlueTintColor,
                      itemDisableColor: .fyItemDisableColor,
                      itemBackgroundColor: .white,
                      backgroundColor: UIColor(white: 0.1, alpha: 0.9))
}
