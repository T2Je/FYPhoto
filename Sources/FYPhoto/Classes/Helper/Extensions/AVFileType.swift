//
//  AVFileType.swift
//  
//
//  Created by xiaoyang on 2021/11/11.
//

import Foundation
import AVFoundation
import MobileCoreServices

extension AVFileType {
    /// Fetch and extension for a file from UTI string
    var fileExtension: String {
        if #available(iOS 14.0, *) {
            if let utType = UTType(self.rawValue) {                
                return utType.preferredFilenameExtension ?? "None"
            }
            return "None"
        } else {
            if let ext = UTTypeCopyPreferredTagWithClass(self as CFString,
                                                         kUTTagClassFilenameExtension)?.takeRetainedValue() {
                return ext as String
            }
            return "None"
        }
    }
}
