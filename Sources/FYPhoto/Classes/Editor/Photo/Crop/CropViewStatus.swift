//
//  CropViewStatus.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import Foundation

enum CropViewHandle {
    case top
    case leftTop
    case left
    case leftBottom
    case bottom
    case rightBottom
    case right
    case rightTop
}

enum CropViewStatus {
    case initial
    case touchImage
    case touchHandle(_ handle: CropViewHandle)
    case imageRotation
    case endTouch
}
