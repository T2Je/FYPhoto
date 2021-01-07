//
//  AssetTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation

public class PhotoPushTransitionController: NSObject {
    weak var navigationController: UINavigationController?

    var initiallyInteractive = false
    var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()

    var pushPopTransitioning: PhotoHideShowAnimator?
    var interactiveTransitioning: PhotoInteractiveForPushAnimator?

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


extension PhotoPushTransitionController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {        
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let interactiveTransitioning = self.interactiveTransitioning else {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            let translationIsVertical = (translation.y > 0) && (abs(translation.y) > abs(translation.x))
//            print(#function, translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1))
            return translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1)
        }
        return interactiveTransitioning.transitionDriver?.isInteractive ?? true
    }
}

extension PhotoPushTransitionController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        var result: UIViewControllerAnimatedTransitioning? = nil
        if fromVC is PhotoTransitioning, operation == .push {
            if let transitionToVC = toVC as? PhotoTransitioning {
                if transitionToVC.enablePhotoTransitionPush() {
                    result = PhotoHideShowAnimator(isPresenting: operation == .push)
                }
            }
        } else if toVC is PhotoTransitioning, operation == .pop {
            if let transitionFromVC = fromVC as? PhotoTransitioning {
                if transitionFromVC.enablePhotoTransitionPush() {
                    if initiallyInteractive {
                        result = PhotoInteractiveForPushAnimator(panGestureRecognizer: panGestureRecognizer)
                    } else {
                        result = PhotoHideShowAnimator(isPresenting: operation == .push)
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

    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return currentAnimationTransition as? UIViewControllerInteractiveTransitioning
    }
}
