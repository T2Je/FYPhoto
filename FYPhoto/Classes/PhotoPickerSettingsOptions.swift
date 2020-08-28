//
//  PhotoPickerSettingsOptions.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation

public struct PhotoPickerSettingsOptions: OptionSet {
    public let rawValue: Int

    public static let displayCounterLabel = PhotoPickerSettingsOptions(rawValue: 1 << 0)

    public static let displayHorizontalScrollIndicator = PhotoPickerSettingsOptions(rawValue: 1 << 1)
    public static let displayVerticalScrollIndicator = PhotoPickerSettingsOptions(rawValue: 1 << 2)

    public static let enableSingleTapDismiss = PhotoPickerSettingsOptions(rawValue: 1 << 3)

    public static let `default`: PhotoPickerSettingsOptions = [.displayCounterLabel, .displayHorizontalScrollIndicator, .displayVerticalScrollIndicator, .enableSingleTapDismiss]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
