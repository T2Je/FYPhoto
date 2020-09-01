//
//  TransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation

protocol TransitionDriver {
    var transitionAnimator: UIViewPropertyAnimator! { get set }
    var isInteractive: Bool { get }
}

extension TransitionDriver {
    internal static func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        CGRect.makeRect(aspectRatio: image.size, insideRect: view.bounds)
    }
}
