//
//  AssetTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import UIKit

class PhotoPushTransitionController: NSObject {
    weak var navigationController: UINavigationController?

    /// An alternative way when viewController doesn't conform to PhotoTransition
    let transitionEssential: TransitionEssentialClosure?

    var initiallyInteractive = false
    var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()

    var pushPopTransitioning: PhotoHideShowAnimator?
    var interactiveTransitioning: PhotoInteractiveAnimator?

    fileprivate var currentAnimationTransition: UIViewControllerAnimatedTransitioning?

    init(navigationController nc: UINavigationController, transitionEssential: TransitionEssentialClosure?) {
        navigationController = nc
        self.transitionEssential = transitionEssential
        super.init()

        nc.delegate = self
        configurePanGestureRecognizer()
    }

    func configurePanGestureRecognizer() {
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.addTarget(self, action: #selector(initiateTransitionInteractively(_:)))
        navigationController?.view.addGestureRecognizer(panGesture)

        guard let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer else { return }
        panGesture.require(toFail: interactivePopGestureRecognizer)
    }

    @objc func initiateTransitionInteractively(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began && interactiveTransitioning?.transitionDriver == nil {
            initiallyInteractive = true
            _ = navigationController?.popViewController(animated: true)
            UIViewController.TransitionHolder.clearNaviTransition()
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
            let translation = panGesture.translation(in: panGesture.view)
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
        var result: UIViewControllerAnimatedTransitioning?
        if operation == .push {
            if fromVC is PhotoTransitioning {
                if let transitionToVC = toVC as? PhotoTransitioning {
                    if transitionToVC.enablePhotoTransitionPush() {
                        result = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: true, transitionEssential: nil, completion: nil)
                    }
                }
            } else {
                result = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: true, transitionEssential: self.transitionEssential, completion: nil)
            }
        } else {
            if toVC is PhotoTransitioning {
                if let transitionFromVC = fromVC as? PhotoTransitioning {
                    if transitionFromVC.enablePhotoTransitionPush() {
                        if initiallyInteractive {
                            result = PhotoInteractiveAnimator(panGestureRecognizer: panGesture,
                                                              isNavigationDismiss: true,
                                                              transitionEssential: nil,
                                                              completion: { [weak self] (isCancelled, _) in
                                                                self?.initiallyInteractive = false
                                                                if !isCancelled {
                                                                    self?.completePopTransition()
                                                                }
                            })
                        } else {
                            result = PhotoHideShowAnimator(isPresenting: false, isNavigationAnimation: true, transitionEssential: nil, completion: { [weak self] in
                                self?.completePopTransition()
                            })
                        }
                    }
                }
            } else { // Alternative transition
                if initiallyInteractive {
                    result = PhotoInteractiveAnimator(panGestureRecognizer: panGesture,
                                                      isNavigationDismiss: true,
                                                      transitionEssential: transitionEssential,
                                                      completion: { [weak self] (isCancelled, _) in
                                                        self?.initiallyInteractive = false
                                                        if !isCancelled {
                                                            self?.completePopTransition()
                                                        }
                    })
                } else {
                    result = PhotoHideShowAnimator(isPresenting: false, isNavigationAnimation: true, transitionEssential: transitionEssential, completion: { [weak self] in
                        self?.completePopTransition()
                    })
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

    func completePopTransition() {
        UIViewController.TransitionHolder.clearViewControllerTransition()
        navigationController?.view.removeGestureRecognizer(panGesture)
        navigationController?.delegate = nil
    }

}
