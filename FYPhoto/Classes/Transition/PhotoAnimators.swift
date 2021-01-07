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

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
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
                                                 context: transitionContext,
                                                 duration: transitionDuration(using: transitionContext))
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
    }
}



// MARK: - InteractiveTransitioning
class PhotoInteractiveForPushAnimator: NSObject, UIViewControllerInteractiveTransitioning {
    var transitionDriver: TransitionDriver?
    let panGestureRecognizer: UIPanGestureRecognizer
    init(panGestureRecognizer: UIPanGestureRecognizer) {
        self.panGestureRecognizer = panGestureRecognizer
        super.init()
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        // Create our helper object to manage the transition for the given transitionContext.
        if transitionContext.isInteractive {
            transitionDriver = PhotoInteractiveDismissTransitionDriver(context: transitionContext,
                                                                       panGestureRecognizer: panGestureRecognizer)
        }
    }
}

extension PhotoInteractiveForPushAnimator: UIViewControllerAnimatedTransitioning {
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

//
class PhotoInteractiveForPresentAnimator: NSObject, UIViewControllerInteractiveTransitioning {
    var transitionDriver: TransitionDriver?
    var panGesture: UIPanGestureRecognizer?
            
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let panGesture = UIPanGestureRecognizer()
        panGesture.maximumNumberOfTouches = 1
        let containerView = transitionContext.containerView
        containerView.addGestureRecognizer(panGesture)
        self.panGesture = panGesture
        // Create our helper object to manage the transition for the given transitionContext.
        if transitionContext.isInteractive {
            transitionDriver = PhotoInteractiveDismissTransitionDriver(context: transitionContext,
                                                                       panGestureRecognizer: panGesture)
        }
    }
    
    
}

extension PhotoInteractiveForPresentAnimator: UIViewControllerAnimatedTransitioning {
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

