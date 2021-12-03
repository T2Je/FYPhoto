//
//  PhotoRotationDegree.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/25.
//

import Foundation
import CoreGraphics

enum PhotoRotation: Int {
    case zero
    case counterclockwise90
    case counterclockwise180
    case counterclockwise270
//    case custom(radians: Double)

    var radians: CGFloat {
        switch self {
        case .zero:
            return 0
        case .counterclockwise90:
            return -CGFloat.pi/2
        case .counterclockwise180:
            return -CGFloat.pi
        case .counterclockwise270:
            return -CGFloat.pi*1.5
//        case .custom(radians: let value):
//            return value
        }
    }

    var degree: CGFloat {
        get {
            return radians / CGFloat.pi * 180.0
        }
    }

    mutating func counterclockwiseRotate90Degree() {
        switch self {
        case .zero:
            self = .counterclockwise90
        case .counterclockwise90:
            self = .counterclockwise180
        case .counterclockwise180:
            self = .counterclockwise270
        case .counterclockwise270:
            self = .zero
//        case .custom(radians: let radians):
//            self = .custom(radians: radians + Double.pi / 2)
        }
    }
}
