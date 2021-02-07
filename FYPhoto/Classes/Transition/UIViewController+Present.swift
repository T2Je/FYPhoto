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
    
    /// Presents a view controller with fyphoto transition.
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to display over the current view controller’s content.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    ///   - completion: The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
    ///   - transitionView: A block to generate a imageView when animating. It's a alternate plan for viewController
    ///   that do not implement PhotoTransition protocol.
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?, transitionEssential: ((_ page: Int) -> PresentingVCTransitionEssential?)? = nil) {
        let transition = PhotoPresentTransitionController(viewController: viewControllerToPresent, transitionEssential: transitionEssential)
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.transitioningDelegate = transition
        wrappedValue.present(viewControllerToPresent, animated: animated, completion: {
            completion?()
        })
        UIViewController.TransitionHolder.storeViewControllerTransition(transition)
    }
    
}

extension TypeWrapperProtocol where WrappedType: UINavigationController {
    /// Pushes a view controller onto the receiver’s stack and updates the display with fyphoto transition.
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack. This object cannot be a tab bar controller. If the view controller is already on the navigation stack, this method throws an exception.
    ///   - animated: Specify true to animate the fyphoto transition or false if you do not want the transition to be animated. You might specify false if you are setting up the navigation controller at launch time.
    ///   - transitionView: A block to generate a imageView when animating. It's a alternate plan for viewController
    ///   that do not implement PhotoTransition protocol.
    public func push(_ viewController: UIViewController, animated: Bool, transitionEssential: ((_ page: Int) -> PresentingVCTransitionEssential)? = nil) {
        let transition = PhotoPushTransitionController(navigationController: wrappedValue, transitionEssential: transitionEssential)
        wrappedValue.delegate = transition
        wrappedValue.pushViewController(viewController, animated: true)
        UIViewController.TransitionHolder.storeNaviTransition(transition)
    }
}
