//
//  CroppedRestoreData.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/6/23.
//

import Foundation
import UIKit

/// data for restore previous cropped data
public struct CroppedRestoreData {
    let initialFrame: CGRect
    let initialZoomScale: CGFloat
    let cropFrame: CGRect
    let zoomScale: CGFloat
    var zoomRect: CGRect?
    var contentOffset: CGPoint?
    let rotation: PhotoRotation
    let originImage: UIImage
    let editedImage: UIImage
}
