//
//  CropViewModel.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import Foundation
import UIKit

class CropViewModel: NSObject {
    var statusChanged: ((CropViewStatus) -> Void)?
//    var aspectRatioChanged: ((PhotoAspectRatio) -> Void)?

    /// initial frames of 4 rotation degrees
    private var _initialFrames: [CGRect] = Array(repeating: .zero, count: 4)
    private var _initialZoomScales: [CGFloat] = Array(repeating: .zero, count: 4)

    /// initial frame of the imageView. Need to be reseted when device rotates.
    var initialFrame: CGRect {
        _initialFrames[rotation.rawValue]
    }

    var initalZoomScale: CGFloat {
        _initialZoomScales[rotation.rawValue]
    }

    let image: UIImage

    var isPortrait = true

    var status: CropViewStatus = .initial {
        didSet {
            statusChanged?(status)
        }
    }

    /// ImageView and CropView intersection area
    @objc dynamic var maximumGuideViewRect: CGRect = .zero

    private(set) var aspectRatio: Double = 0

    var rotation: PhotoRotation = .zero

    init(image: UIImage) {
        self.image = image
        super.init()
        aspectRatio = getImageRatio()
    }

    func getInitialCropGuideViewRect(fromOutside outside: CGRect) -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }

        let inside: CGRect

        if isPortrait {
            if rotation == .counterclockwise90 || rotation == .counterclockwise270 {
                inside = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
            } else {
                inside = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            }
        } else {
            if rotation == .counterclockwise90 || rotation == .counterclockwise270 {
                inside = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            } else {
                inside = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
            }
        }

        return GeometryHelper.getAppropriateRect(fromOutside: outside, inside: inside)
    }

    func getProporateGuideViewRect(fromOutside outside: CGRect) -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }

        let inside: CGRect

        if isPortrait {

            inside = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            inside = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }

        return GeometryHelper.getAppropriateRect(fromOutside: outside, inside: inside)
    }

    // CropGuideView moves around in this area
    func getContentBounds(_ outsideRect: CGRect, _ padding: CGFloat) -> CGRect {
        var rect = outsideRect
        rect.origin.x = rect.origin.x + padding
        rect.origin.y = rect.origin.y + padding
        rect.size.width = rect.size.width - padding * 2
        rect.size.height = rect.size.height - padding * 2
        return rect
    }

    // MARK: Setup
    func setInitialZoomScale(_ zoomScale: CGFloat, at rotation: PhotoRotation) {
        _initialZoomScales[rotation.rawValue] = zoomScale
    }

    func setInitialFrame(_ frame: CGRect, at rotation: PhotoRotation) {
        _initialFrames[rotation.rawValue] = frame
    }

    func resetInitialFrameAtCurrentRotation(_ rect: CGRect) {
        setInitialFrame(rect, at: rotation)
    }

    func resetInitFrame(_ rect: CGRect, imageZoomScale: CGFloat, at rotation: PhotoRotation) {
        setInitialZoomScale(imageZoomScale, at: rotation)
        setInitialFrame(rect, at: rotation)
    }

    func setFixedAspectRatio(_ ratio: Double?) {
        if let ratio = ratio {
            aspectRatio = ratio
        } else {
            aspectRatio = getImageRatio()
        }
    }

    // MARK: -

    private func hasResized(_ currentRect: CGRect) -> Bool {
        initialFrame != currentRect
    }

    func hasChanges(_ currentRect: CGRect, _ zoomScale: CGFloat) -> Bool {
        rotation != .zero || hasResized(currentRect) || zoomScale != initalZoomScale
    }

    func canReset(_ currentRect: CGRect, _ zoomScale: CGFloat) -> Bool {
        hasResized(currentRect) || zoomScale != initalZoomScale
    }

    func calculateGuideViewFrame(by initial: CGRect) -> CGRect {
        var guideViewFrame = initial
        let center = CGPoint(x: initialFrame.midX, y: initialFrame.midY)
        let original = getImageRatio()
        if aspectRatio > original {
            guideViewFrame.size.height = guideViewFrame.width / CGFloat(aspectRatio)
        } else {
            guideViewFrame.size.width = guideViewFrame.height * CGFloat(aspectRatio)
        }

        guideViewFrame.origin.x = center.x - guideViewFrame.width / 2
        guideViewFrame.origin.y = center.y - guideViewFrame.height / 2

        return guideViewFrame
    }

    func getImageRatio() -> Double {
        if rotation == .zero || rotation == .counterclockwise180 {
            return Double(image.size.width / image.size.height)
        } else {
            return Double(image.size.height / image.size.width)
        }
    }
}
