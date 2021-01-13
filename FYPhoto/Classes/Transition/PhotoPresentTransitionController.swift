//
//  PhotoPresentTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

class PhotoPresentTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let panGesture = UIPanGestureRecognizer()
    weak var viewController: UIViewController?
    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
        configurePanGestureRecognizer()
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
            viewController?.dismiss(animated: true) {
                UIViewController.TransitionHolder.clearViewControllerTransition()
                self.viewController?.view.removeGestureRecognizer(panGesture)
            }
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = PhotoHideShowAnimator(isPresenting: true, isNavigationAnimation: false)
        normalAnimator = animator
        return animator
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = PhotoInteractiveAnimator(panGestureRecognizer: panGesture, isNavigationDismiss: false)
        interactiveAnimator = animator
        return animator
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
