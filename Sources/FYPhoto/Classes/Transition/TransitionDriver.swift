//
//  TransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation
import UIKit

typealias TransitionEssentialClosure = ((Int) -> TransitionEssential?)

enum TransitionType {
    case photoTransitionProtocol(from: PhotoTransitioning, to: PhotoTransitioning)
    case transitionBlock(essential: TransitionEssential)
    case noTransitionAnimation // lack of transition info
}

protocol TransitionDriver {
    var transitionAnimator: UIViewPropertyAnimator! { get set }
    var isInteractive: Bool { get }
}

extension TransitionDriver {
    internal static func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        CGRect.makeRect(aspectRatio: image.size, insideRect: view.bounds)
    }
}
