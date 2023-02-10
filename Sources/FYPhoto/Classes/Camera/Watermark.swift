//
//  File.swift
//  
//
//  Created by xiaoyang on 2023/2/9.
//

import Foundation
import UIKit

public protocol WatermarkDataSource: AnyObject {
    func watermarkImage() -> WatermarkImage?
}

public protocol WatermarkDelegate: AnyObject {
    func cameraViewControllerStartAddingWatermark(_ cameraViewController: CameraViewController)
    func camera(_ cameraViewController: CameraViewController, didFinishAddingWatermarkAt path: URL)
}

public extension WatermarkDataSource {
    func watermarkImage() -> WatermarkImage? { return nil }
}

public extension WatermarkDelegate {
    func cameraViewControllerStartAddingWatermark(_ cameraViewController: CameraViewController) {}
    func camera(_ cameraViewController: CameraViewController, didFinishAddingWatermarkAt path: URL) {}
}


public struct WatermarkImage {
    let image: UIImage
    let frame: CGRect

    public init(image: UIImage, frame: CGRect) {
        self.image = image
        self.frame = frame
    }
}
