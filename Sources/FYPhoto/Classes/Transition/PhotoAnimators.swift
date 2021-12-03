//
//  PhotoAnimators.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation
import UIKit

// MARK: - Show / Hide Transitioning
class PhotoHideShowAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var transitionDriver: TransitionDriver?

    let isPresenting: Bool
    let isNavigationAnimation: Bool
    let transitionEssential: TransitionEssentialClosure?
    let completion: (() -> Void)?

    init(isPresenting: Bool, isNavigationAnimation: Bool, transitionEssential: TransitionEssentialClosure?, completion: (() -> Void)?) {
        self.isPresenting = isPresenting
        self.isNavigationAnimation = isNavigationAnimation
        self.transitionEssential = transitionEssential
        self.completion = completion
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isPresenting {
            return 0.48
        } else {
            return 0.38
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionDriver = PhotoTransitionDriver(isPresenting: isPresenting,
                                                 isNavigationAnimation: isNavigationAnimation,
                                                 context: transitionContext,
                                                 duration: transitionDuration(using: transitionContext),
                                                 transitionEssential: transitionEssential)
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
        completion?()
    }
}

// MARK: - InteractiveTransitioning
class PhotoInteractiveAnimator: NSObject, UIViewControllerInteractiveTransitioning {
    var transitionDriver: TransitionDriver?
    let panGestureRecognizer: UIPanGestureRecognizer
    let isNavigationDismiss: Bool
    let transitionEssential: TransitionEssentialClosure?
    let completion: ((_ isCancelled: Bool, _ isNavigation: Bool) -> Void)?

    init(panGestureRecognizer: UIPanGestureRecognizer, isNavigationDismiss: Bool, transitionEssential: TransitionEssentialClosure?, completion: ((_ isCancelled: Bool, _ isNavigation: Bool) -> Void)?) {
        self.panGestureRecognizer = panGestureRecognizer
        self.isNavigationDismiss = isNavigationDismiss
        self.transitionEssential = transitionEssential
        self.completion = completion
        super.init()
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        // Create our helper object to manage the transition for the given transitionContext.
        if transitionContext.isInteractive {
            transitionDriver = PhotoInteractiveDismissTransitionDriver(context: transitionContext,
                                                                       panGestureRecognizer: panGestureRecognizer,
                                                                       isNavigationDismiss: isNavigationDismiss,
                                                                       transitionEssential: transitionEssential,
                                                                       completion: completion)
        }
    }
}

extension PhotoInteractiveAnimator: UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        fatalError("never called")
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.38
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
    }
}
