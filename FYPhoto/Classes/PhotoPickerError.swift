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
            return "VideoDurationTooLong".photoTablelocalized
        case .VideoMemoryOutOfSize:
            return "VideoMemoryOutOfSize".photoTablelocalized
        case .UnspportedVideoFormat:
            return "UnspportedVideoFormat".photoTablelocalized
        }
    }
}

