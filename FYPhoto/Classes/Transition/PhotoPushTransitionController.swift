//
//  AssetTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation

public class PhotoPushTransitionController: NSObject {
    weak var navigationController: UINavigationController?
    
    /// An alternative way when viewController doesn't conform to PhotoTransition
    let transitionView: (() -> UIImageView?)?
    
    var initiallyInteractive = false
    var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()

    var pushPopTransitioning: PhotoHideShowAnimator?
    var interactiveTransitioning: PhotoInteractiveAnimator?
    
    fileprivate var currentAnimationTransition: UIViewControllerAnimatedTransitioning? = nil

    @objc public init(navigationController nc: UINavigationController, transitionView: (() -> UIImageView?)?) {
        navigationController = nc
        self.transitionView = transitionView
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
            let _ = navigationController?.popViewController(animated: true)
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
        var result: UIViewControllerAnimatedTransitioning? = nil
        if operation == .push {
            if fromVC is PhotoTransitioning {
                if let transitionToVC = toVC as? PhotoTransitioning {
                    if transitionToVC.enablePhotoTransitionPush() {
                        result = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: true, transitionView: nil)
                    }
                }
            } else if let transitionView = transitionView {
                result = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: true, transitionView: transitionView)
            }
        } else {
            if toVC is PhotoTransitioning {
                if let transitionFromVC = fromVC as? PhotoTransitioning {
                    if transitionFromVC.enablePhotoTransitionPush() {
                        if initiallyInteractive {
                            result = PhotoInteractiveAnimator(panGestureRecognizer: panGesture,
                                                              isNavigationDismiss: true,
                                                              transitionView: nil,
                                                              completion: { [weak self] isNavigation in
                                self?.completeInteractiveDismiss(isNavigation)
                            })
                        } else {
                            result = PhotoHideShowAnimator(isPresenting: false, isNavigationAnimation: true, transitionView: nil)
                        }
                    }
                }
            } else if let transitionView = transitionView { // Alternative transition
                if initiallyInteractive {
                    result = PhotoInteractiveAnimator(panGestureRecognizer: panGesture,
                                                      isNavigationDismiss: true,
                                                      transitionView: transitionView,
                                                      completion: { [weak self] isNavigation in
                        self?.completeInteractiveDismiss(isNavigation)
                    })
                } else {
                    result = PhotoHideShowAnimator(isPresenting: false, isNavigationAnimation: true, transitionView: transitionView)
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
    
    func completeInteractiveDismiss(_ isNavi: Bool) {
        if isNavi {
            UIViewController.TransitionHolder.clearNaviTransition()
        } else {
            UIViewController.TransitionHolder.clearViewControllerTransition()
        }
        navigationController?.view.removeGestureRecognizer(panGesture)
    }
}
