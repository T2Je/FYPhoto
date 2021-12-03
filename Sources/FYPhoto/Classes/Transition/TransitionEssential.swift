//
//  TransitionEssential.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/5.
//

import Foundation
import UIKit

/// Transition animation needs these infos to find out which image to show and where is it.
public struct TransitionEssential {
    let transitionImage: UIImage?
    /// frame coverted to viewController view
    let convertedFrame: CGRect

    /// Initial essentials
    /// - Parameters:
    ///   - transitionImage: Transition uses the image for animation
    ///   - convertedFrame: Location of the image in the ViewController. e.g., imageView.convert(imageView.bounds, to: viewControllerView)
    public init(transitionImage: UIImage?, convertedFrame: CGRect) {
        self.transitionImage = transitionImage
        self.convertedFrame = convertedFrame
    }
}
