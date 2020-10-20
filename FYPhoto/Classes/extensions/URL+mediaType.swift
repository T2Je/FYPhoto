//
//  URL+mediaType.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/16.
//

import Foundation
import MobileCoreServices
import AVFoundation

extension URL {
    func isImage() -> Bool {
        let filePathURL = URL(fileURLWithPath: absoluteString)
        let pathExtension = filePathURL.pathExtension
        guard !pathExtension.isEmpty else {
            return false
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil) else {
            return false
        }
        return UTTypeConformsTo(uti.takeRetainedValue(), kUTTypeImage)
    }

    func isVideo() -> Bool {
        let filePathURL = URL(fileURLWithPath: absoluteString)
        let pathExtension = filePathURL.pathExtension
        guard !pathExtension.isEmpty else {
            return false
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil) else {
            return false
        }
        return UTTypeConformsTo(uti.takeRetainedValue(), kUTTypeMovie)
    }
}
