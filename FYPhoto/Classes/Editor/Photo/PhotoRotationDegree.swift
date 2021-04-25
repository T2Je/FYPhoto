//
//  PhotoRotationDegree.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/25.
//

import Foundation

enum PhotoRotationDegree {
    case zero
    case counterclockwise90
    case counterclockwise180
    case counterclockwise270
    case custom(radians: CGFloat)
    
    var radians: CGFloat {
        switch self {
        case .zero:
            return 0
        case .counterclockwise90:
            return 90
        case .counterclockwise180:
            return 180
        case .counterclockwise270:
            return 270
        case .custom(radians: let value):
            return value
        }
    }
    
    var degree: CGFloat {
        get {
            return radians / CGFloat.pi * 180.0
        }
    }
        
}
