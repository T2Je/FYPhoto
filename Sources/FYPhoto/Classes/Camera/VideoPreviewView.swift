//
//  VideoPreviewView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/24.
//
//  Abstract:
//  The camera preview view that displays the capture output.

import UIKit
import AVFoundation

class VideoPreviewView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        layer.videoGravity = .resizeAspect
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
