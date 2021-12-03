//
//  PhotoPresentTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation
import UIKit

class PhotoPresentTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let panGesture = UIPanGestureRecognizer()
    let transitionEssential: TransitionEssentialClosure?

    var isInteractive: Bool = false

    weak var viewController: UIViewController?
    init(viewController: UIViewController?, transitionEssential: TransitionEssentialClosure?) {
        self.viewController = viewController
        self.transitionEssential = transitionEssential
        super.init()
        configurePanGestureRecognizer()
    }

    deinit {
//        UIViewController.TransitionHolder.clearViewControllerTransition()
//        self.viewController?.view.removeGestureRecognizer(panGesture)
    }

    var interactiveAnimator: PhotoInteractiveAnimator?
    var normalAnimator: UIViewControllerAnimatedTransitioning?

    func configurePanGestureRecognizer() {
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.addTarget(self, action: #selector(initiateTransitionInteractively(_:)))
        viewController?.view.addGestureRecognizer(panGesture)
    }

    @objc func initiateTransitionInteractively(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began && interactiveAnimator?.transitionDriver == nil {
            isInteractive = true
            viewController?.dismiss(animated: true) {}
        }
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: false, transitionEssential: transitionEssential, completion: nil)
        normalAnimator = animator
        return animator
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator: UIViewControllerAnimatedTransitioning
        if isInteractive {
            let interactiveAnimator = PhotoInteractiveAnimator(panGestureRecognizer: panGesture, isNavigationDismiss: false, transitionEssential: transitionEssential, completion: { [weak self] (isCancelled, _) in
                self?.interactiveAnimator = nil
                self?.isInteractive = false
                if !isCancelled {
                    self?.completePresentationTransition()
                }
            })
            self.interactiveAnimator = interactiveAnimator
            animator = interactiveAnimator
        } else {
            animator = PhotoHideShowAnimator(isPresenting: false, isNavigationAnimation: false, transitionEssential: transitionEssential, completion: { [weak self] in
                self?.completePresentationTransition()
            })
            normalAnimator = animator
        }

        return animator
    }

    func completePresentationTransition() {
        UIViewController.TransitionHolder.clearViewControllerTransition()
        viewController?.view.removeGestureRecognizer(panGesture)
    }
}

extension PhotoPresentTransitionController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let interactiveAnimator = self.interactiveAnimator else {
            let translation = panGesture.translation(in: panGesture.view)
            let translationIsVertical = (translation.y > 0) && (abs(translation.y) > abs(translation.x))
//            print(#function, translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1))
            return translationIsVertical
        }
        return interactiveAnimator.transitionDriver?.isInteractive ?? true
    }
}
