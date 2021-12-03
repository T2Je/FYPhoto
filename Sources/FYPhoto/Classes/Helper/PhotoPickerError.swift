//
//  PhotoPickerError.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/23.
//

import Foundation

public enum PhotoPickerError: Error {
    case VideoDurationTooLong
    case VideoMemoryOutOfSize
    case UnspportedVideoFormat
}

extension PhotoPickerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .VideoDurationTooLong:
            return L10n.videoDurationTooLong
        case .VideoMemoryOutOfSize:
            return L10n.videoMemoryOutOfSize
        case .UnspportedVideoFormat:
            return L10n.unspportedVideoFormat
        }
    }
}

public enum AVAssetExportSessionError: Error {
    case exportSessionCreationFailed
    case exportStatuUnknown
}
