//
//  GeometryHelper.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import Foundation

struct GeometryHelper {
    
    /// Calculate appropriate rect for cropView from two rects
    /// - Parameters:
    ///   - outside: outside view
    ///   - inside: inside view (guide view)
    /// - Returns: rect
    func getAppropriateRect(fromOutside outside: CGRect, andInside inside: CGRect) -> CGRect {
        var rect = inside
        let outsideRatio = outside.width / outside.height
        let insideRatio = inside.width / inside.height
        
        if outsideRatio > insideRatio {
            rect.size.width *= (outside.height / inside.height)
            rect.size.height = outside.height
        } else if outsideRatio < insideRatio {
            rect.size.height *= (outside.width / inside.width)
            rect.size.width = outside.width
        }
        
        rect.origin.x = outside.midX - rect.width / 2
        rect.origin.y = outside.midY - rect.height / 2
        return rect
    }
}
