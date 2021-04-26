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
    case custom(radians: Double)
    
    var radians: Double {
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
    
    var degree: Double {
        get {
            return radians / Double.pi * 180.0
        }
    }
    
    func counterclockwiseRotate90Degree() -> PhotoRotationDegree {
        switch self {
        case .zero:
            return .counterclockwise90
        case .counterclockwise90:
            return .counterclockwise180
        case .counterclockwise180:
            return .counterclockwise270
        case .counterclockwise270:
            return .zero
        case .custom(radians: let radians):
            return .custom(radians: radians + Double.pi / 2)
        }
    }
}
