//
//  GeometryHelper.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import Foundation
import CoreGraphics

struct GeometryHelper {

    /// Calculate appropriate rect within the outside coordinator for cropView from two rects.
    /// - Parameters:
    ///   - outside: outside view
    ///   - inside: inside view (guide view)
    /// - Returns: rect
    static func getAppropriateRect(fromOutside outside: CGRect, inside: CGRect) -> CGRect {
        var rect = CGRect(origin: .zero, size: inside.size)
        let outsideRatio = outside.width / outside.height
        let insideRatio = inside.width / inside.height

        if outsideRatio >= insideRatio {
            rect.size.width *= (outside.height / inside.height)
            rect.size.height = outside.height
        } else if outsideRatio < insideRatio {
            rect.size.height *= (outside.width / inside.width)
            rect.size.width = outside.width
        }

        // reset precision
        let tempX = ((outside.midX - rect.width / 2) * 100).rounded(.toNearestOrAwayFromZero) / 100
        let tempY = ((outside.midY - rect.height / 2) * 100).rounded(.toNearestOrAwayFromZero) / 100
        rect.origin.x = tempX
        rect.origin.y = tempY

        return rect
    }
}
