//
//  AVAsset+VideoSize.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/21.
//

import Foundation
import AVKit
import Photos

extension AVAsset {
    func dataSize() -> Float? {
        guard let lastTrackTotal = tracks(withMediaType: .video).last?.totalSampleDataLength else {
            return nil
        }
        return Float(lastTrackTotal) / 1024 / 1024
    }
}
