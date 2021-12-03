//
//  TimeInterval+VideoFormat.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/25.
//

import Foundation

extension Double {
    /// Get time string from timeInterval, timeInterval > 3600, retrun '> 1 hour'. TimeInterval in (60, 3600), return 'xx:yy'.
    /// TimeInterval less than 10, return '00:xx'.
    ///
    /// - Returns: e.g. 00:00
    func videoDurationFormat() -> String {
        guard self != 0 else { return "00:00" }
        guard self / Double(3600) < 1 else {
            return String(format: "> 1 %@", L10n.hour)
        }
        let minutes = Int(ceil(self)) / 60
        let seconds = Int(ceil(self)) % 60

        let fixedSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        if minutes == 0 {
            return "00:\(fixedSeconds)"
        } else {
            return String(format: "%d:%@", minutes, fixedSeconds)
        }
    }

    static func zeroDurationFormat() -> String {
        return 0.videoDurationFormat()
    }
}
