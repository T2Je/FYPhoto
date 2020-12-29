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
            return "selected video duration larger than expected"
        case .VideoMemoryOutOfSize:
            return "selected video out of size"
        case .UnspportedVideoFormat:
            return "unspported video format"
        }
    }
}

