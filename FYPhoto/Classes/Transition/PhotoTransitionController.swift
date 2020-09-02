//
//  AssetTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation

let assetTransitionDuration = 0.8

public class PhotoTransitionController: NSObject {
    weak var navigationController: UINavigationController?
    var operation: UINavigationController.Operation = .none
    var transitionDriver: TransitionDriver?
    var initiallyInteractive = false
    var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()

    public init(navigationController nc: UINavigationController) {
        navigationController = nc
        super.init()

        nc.delegate = self
        configurePanGestureRecognizer()
    }

    func configurePanGestureRecognizer() {
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.addTarget(self, action: #selector(initiateTransitionInteractively(_:)))
        navigationController?.view.addGestureRecognizer(panGestureRecognizer)

        guard let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer else { return }
        panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
    }

    @objc func initiateTransitionInteractively(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began && transitionDriver == nil {
            initiallyInteractive = true
            let _ = navigationController?.popViewController(animated: true)
        }
    }
}


extension PhotoTransitionController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let transitionDriver = self.transitionDriver else {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            let translationIsVertical = (translation.y > 0) && (abs(translation.y) > abs(translation.x))
            print(#function, translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1))
            return translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1)
        }

        print("transitionDriver.isInteractive = \(transitionDriver.isInteractive)")
        return transitionDriver.isInteractive
    }
}

extension PhotoTransitionController: UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Remember the direction of the transition (.push or .pop)
        print(#function)


        self.operation = operation
        if fromVC is PhotoTransitioning, operation == .push {
            if let transitionToVC = toVC as? PhotoTransitioning {
                if transitionToVC.enablePhotoTransitionPush() {
                    return self
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else if toVC is PhotoTransitioning, operation == .pop {
            if let transitionFromVC = fromVC as? PhotoTransitioning {
                if transitionFromVC.enablePhotoTransitionPush() {
                    return self
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
        // Return ourselves as the animation controller for the pending transition
//        return self
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        print(#function)
        // Return ourselves as the interaction controller for the pending transition
        return self
    }
}


extension PhotoTransitionController: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        print(#function)
        if operation == .push {
            return 0.4
        } else {
            return 0.38
        }
//        return 1
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
    }

    public func animationEnded(_ transitionCompleted: Bool) {
        // Clean up our helper object and any additional state
//        if operation == .pop {
//            navigationController?.setToolbarHidden(true, animated: false)
//        }
        transitionDriver = nil
        initiallyInteractive = false
        operation = .none

        print(#function)
    }

    public func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        // The transition driver (helper object), creates the UIViewPropertyAnimator (transitionAnimator)
        // to be used for this transition. It must live the lifetime of the transitionContext.
        print(#function)
        return (transitionDriver?.transitionAnimator)!
    }
}

extension PhotoTransitionController: UIViewControllerInteractiveTransitioning {
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
        // Create our helper object to manage the transition for the given transitionContext.
        if transitionContext.isInteractive {
            transitionDriver = PhotoInteractiveDismissTransitionDriver(context: transitionContext, panGestureRecognizer: panGestureRecognizer, duration: transitionDuration(using: transitionContext))
        } else {
            transitionDriver = PhotoPushPopTransitionDriver(operation: operation, context: transitionContext, duration: transitionDuration(using: transitionContext))
        }
    }

    public var wantsInteractiveStart: Bool {
        // Determines whether the transition begins in an interactive state
        print(#function)
        return initiallyInteractive
    }
}
