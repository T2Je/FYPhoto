//
//  FYPhotoCacheCleaner.swift
//  
//
//  Created by xiaoyang on 2021/11/8.
//

import Foundation
import SDWebImage

public class FYPhotoCacheCleaner {
    public static func clearMemory() {
        SDImageCache.shared.clearMemory()
    }

    public static func clearDisk() {
        SDImageCache.shared.clearDisk {}
        VideoCache.shared?.clearAll()
        VideoTrimmer.shared.clear()
        PhotoPickerResource.shared.clearCache()
    }
}
