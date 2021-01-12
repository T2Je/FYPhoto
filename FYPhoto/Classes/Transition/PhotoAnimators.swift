//
//  PhotoAnimators.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

// MARK: - Show / Hide Transitioning
class PhotoHideShowAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var transitionDriver: TransitionDriver?

    let isPresenting: Bool
    let isNavigationAnimation: Bool
    
    init(isPresenting: Bool, isNavigationAnimation: Bool) {
        self.isPresenting = isPresenting
        self.isNavigationAnimation = isNavigationAnimation
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isPresenting {
            return 0.38
        } else {
            return 0.38
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionDriver = PhotoTransitionDriver(isPresenting: isPresenting,
                                                 isNavigationAnimation: isNavigationAnimation,
                                                 context: transitionContext,
                                                 duration: transitionDuration(using: transitionContext))
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
    }
}



// MARK: - InteractiveTransitioning
class PhotoInteractiveAnimator: NSObject, UIViewControllerInteractiveTransitioning {
    var transitionDriver: TransitionDriver?
    let panGestureRecognizer: UIPanGestureRecognizer
    let isNavigationDismiss: Bool
    
    init(panGestureRecognizer: UIPanGestureRecognizer, isNavigationDismiss: Bool) {
        self.panGestureRecognizer = panGestureRecognizer
        self.isNavigationDismiss = isNavigationDismiss
        super.init()
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        // Create our helper object to manage the transition for the given transitionContext.
        if transitionContext.isInteractive {
            transitionDriver = PhotoInteractiveDismissTransitionDriver(context: transitionContext,
                                                                       panGestureRecognizer: panGestureRecognizer, isNavigationDismiss: isNavigationDismiss)
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
