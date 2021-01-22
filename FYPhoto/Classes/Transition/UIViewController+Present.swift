//
//  UIViewController+Present.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

extension UIViewController: FYNameSpaceProtocol {
    struct TransitionHolder {
        private static var _viewControllerTransition: UIViewControllerTransitioningDelegate?
        private static var _naviTransition: UINavigationControllerDelegate?
        
        static func storeViewControllerTransition(_ transition: UIViewControllerTransitioningDelegate) {
            _viewControllerTransition = transition
        }
        static func storeNaviTransition(_ transition: UINavigationControllerDelegate) {
            _naviTransition = transition
        }
        static func clearViewControllerTransition() {
            _viewControllerTransition = nil
        }
        
        static func clearNaviTransition() {
            _viewControllerTransition = nil
        }
    }
}

extension TypeWrapperProtocol where WrappedType: UIViewController {
    
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?, transitionView: (() -> UIImageView?)? = nil) {
        let transition = PhotoPresentTransitionController(viewController: viewControllerToPresent, transitionView: transitionView)
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.transitioningDelegate = transition
        wrappedValue.present(viewControllerToPresent, animated: animated, completion: {
            completion?()
        })
        UIViewController.TransitionHolder.storeViewControllerTransition(transition)
    }

    
}

extension TypeWrapperProtocol where WrappedType: UINavigationController {
    public func push(_ viewController: UIViewController, animated: Bool, transitionView: (() -> UIImageView?)? = nil) {
        let transition = PhotoPushTransitionController(navigationController: wrappedValue, transitionView: transitionView)
        wrappedValue.delegate = transition
        wrappedValue.pushViewController(viewController, animated: true)
        UIViewController.TransitionHolder.storeNaviTransition(transition)
    }
}
