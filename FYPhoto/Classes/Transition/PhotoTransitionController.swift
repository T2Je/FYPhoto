//
//  AssetTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation

public class PhotoTransitionController: NSObject {
    weak var navigationController: UINavigationController?

    var initiallyInteractive = false
    var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()

    var pushPopTransitioning: PushPopTransitioning?
    var interactiveTransitioning: InteractiveTransitioning?

    fileprivate var currentAnimationTransition: UIViewControllerAnimatedTransitioning? = nil

    @objc public init(navigationController nc: UINavigationController) {
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
        if panGesture.state == .began && interactiveTransitioning?.transitionDriver == nil {
            initiallyInteractive = true
            let _ = navigationController?.popViewController(animated: true)
        } else {
            initiallyInteractive = false
        }
    }
}


extension PhotoTransitionController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {        
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let interactiveTransitioning = self.interactiveTransitioning else {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            let translationIsVertical = (translation.y > 0) && (abs(translation.y) > abs(translation.x))
            print(#function, translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1))
            return translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1)
        }
        return interactiveTransitioning.transitionDriver?.isInteractive ?? true
    }
}

extension PhotoTransitionController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        var result: UIViewControllerAnimatedTransitioning? = nil
        if fromVC is PhotoTransitioning, operation == .push {
            if let transitionToVC = toVC as? PhotoTransitioning {
                if transitionToVC.enablePhotoTransitionPush() {
                    result = PushPopTransitioning(operation: operation)
                }
            }
        } else if toVC is PhotoTransitioning, operation == .pop {
            if let transitionFromVC = fromVC as? PhotoTransitioning {
                if transitionFromVC.enablePhotoTransitionPush() {
                    if initiallyInteractive {
                        result = InteractiveTransitioning(panGestureRecognizer: panGestureRecognizer)
                    } else {
                        result = PushPopTransitioning(operation: operation)
                    }
                }
            }
        }
        self.currentAnimationTransition = result
        return result
        // Return ourselves as the animation controller for the pending transition it's not the best idea.
        // There is problem if we return self as the animation controller. A shows navigationBar, then it pushes to B,
        // if B hide the navigationBar, it will cause navigationBar to disappear(A, B are viewcontrollers).
        // Everytime you set navigationBar hidden or not, it's alpha will becomes 0. It's weired 🤔.
//        return self
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {                
        return currentAnimationTransition as? UIViewControllerInteractiveTransitioning
    }
}

// MARK: - InteractiveTransitioning
class InteractiveTransitioning: NSObject, UIViewControllerInteractiveTransitioning {
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
                                                                       panGestureRecognizer: panGestureRecognizer,
                                                                       duration: transitionDuration(using: transitionContext))
        }
    }

}

extension InteractiveTransitioning: UIViewControllerAnimatedTransitioning {
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
// MARK: - PushPopTransitioning
class PushPopTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    var transitionDriver: TransitionDriver?

    let operation: UINavigationController.Operation

    init(operation: UINavigationController.Operation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        print(#function)
        if operation == .push {
            return 0.4
        } else {
            return 0.38
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionDriver = PhotoPushPopTransitionDriver(operation: operation,
                                                        context: transitionContext,
                                                        duration: transitionDuration(using: transitionContext))
    }

    func animationEnded(_ transitionCompleted: Bool) {
        transitionDriver = nil
    }
}
