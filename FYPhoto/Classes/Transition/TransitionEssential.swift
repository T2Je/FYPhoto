//
//  TransitionEssential.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/5.
//

import Foundation

/// Transition animation needs these properties to find out which image to show and where to show
/// For presentation, transitionView will use them to start the animation and for dismission, transitionView will use them to end the animation.
public struct PresentingVCTransitionEssential {
    let transitionImage: UIImage?
    /// frame coverted to viewController view
    let convertedFrame: CGRect
    
    public init(transitionImage: UIImage?, convertedFrame: CGRect) {
        self.transitionImage = transitionImage
        self.convertedFrame = convertedFrame
    }
}
