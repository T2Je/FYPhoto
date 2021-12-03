//
//  UIViewController+Present.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation
import UIKit

extension TypeWrapperProtocol where WrappedType: UIViewController {

    /// Presents PhotoBrowser with fyphoto transition animation.
    ///
    /// Support three ways to display photos (if parameter `animated` is true):
    ///  - presentingViewController and presentedViewController both comform to **PhotoTransition** protocol
    ///  - give a closure to `transitionEssential` parameter
    ///  - neither of the above (will be simply displayed photos in it's final location)
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to display over the current view controller’s content.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    ///   - completion: The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
    ///   - transitionEssential: A closure to generate animation essentials with current item. Set this parameter if you don't want your presentingViewController conforms to **PhotoTransition** protocol.
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil, transitionEssential: ((_ page: Int) -> TransitionEssential?)? = nil) {
        let transition = PhotoPresentTransitionController(viewController: viewControllerToPresent, transitionEssential: transitionEssential)
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.transitioningDelegate = transition
        wrappedValue.present(viewControllerToPresent, animated: animated, completion: {
            completion?()
        })
        UIViewController.TransitionHolder.storeViewControllerTransition(transition)
    }

//    @available(swift, deprecated: 1.1.0, message: "Use present(_ viewControllerToPresent:, animated:, completion:, transitionEssential:) instead")
//    public func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?, transitionView: (() -> UIImageView?)?) {
//
//        let transition = PhotoPresentTransitionController(viewController: viewControllerToPresent) { (_) -> PresentingVCTransitionEssential? in
//            let essential: PresentingVCTransitionEssential?
//            if let closure = transitionView, let imageView = closure() {
//                let frame = imageView.convert(imageView.bounds, to: wrappedValue.view)
//                essential = PresentingVCTransitionEssential(transitionImage: imageView.image, convertedFrame: frame)
//            } else {
//                essential = nil
//            }
//            return essential
//        }
//        viewControllerToPresent.modalPresentationStyle = .custom
//        viewControllerToPresent.transitioningDelegate = transition
//        wrappedValue.present(viewControllerToPresent, animated: animated, completion: {
//            completion?()
//        })
//        UIViewController.TransitionHolder.storeViewControllerTransition(transition)
//    }

}

extension TypeWrapperProtocol where WrappedType: UINavigationController {

    @available(swift, deprecated: 1.2.0, message: "Use pushViewController(_ viewController:, animated:, transitionEssential:) instead")
    public func push(_ viewController: UIViewController, animated: Bool, transitionEssential: ((_ page: Int) -> TransitionEssential)? = nil) {
        let transition = PhotoPushTransitionController(navigationController: wrappedValue, transitionEssential: transitionEssential)
        wrappedValue.delegate = transition
        wrappedValue.pushViewController(viewController, animated: true)
        UIViewController.TransitionHolder.storeNaviTransition(transition)
    }

    /// Pushes PhotoBrowser onto the receiver’s stack and updates the display with fyphoto transition.
    ///
    /// Support three ways to display photos:
    ///  - presentingViewController and presentedViewController both comform to **PhotoTransition** protocol
    ///  - give a closure to `transitionEssential` parameter
    ///  - neither of the above (will be simply displayed photos in it's final location)
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack. This object cannot be a tab bar controller. If the view controller is already on the navigation stack, this method throws an exception.
    ///   - animated: Specify true to animate the fyphoto transition or false if you do not want the transition to be animated. You might specify false if you are setting up the navigation controller at launch time.
    ///   - transitionEssential: A closure to generate animation essentials with current item. Set this parameter if you don't want your presentingViewController conforms to **PhotoTransition** protocol.
    public func pushViewController(_ viewController: UIViewController, animated: Bool, transitionEssential: ((_ page: Int) -> TransitionEssential)? = nil) {
        let transition = PhotoPushTransitionController(navigationController: wrappedValue, transitionEssential: transitionEssential)
        wrappedValue.delegate = transition
        wrappedValue.pushViewController(viewController, animated: true)
        UIViewController.TransitionHolder.storeNaviTransition(transition)
    }

//    @available(swift, deprecated: 1.1.0, message: "Use push(_ viewController:, animated:, transitionEssential:) instead")
//    public func push(_ viewController: UIViewController, animated: Bool, transitionView: (() -> UIImageView?)?) {
//        let transition = PhotoPushTransitionController(navigationController: wrappedValue) { (_) -> PresentingVCTransitionEssential? in
//            let essential: PresentingVCTransitionEssential?
//            if let closure = transitionView, let imageView = closure() {
//                let frame = imageView.convert(imageView.bounds, to: wrappedValue.view)
//                essential = PresentingVCTransitionEssential(transitionImage: imageView.image, convertedFrame: frame)
//            } else {
//                essential = nil
//            }
//            return essential
//        }
//        wrappedValue.delegate = transition
//        wrappedValue.pushViewController(viewController, animated: true)
//        UIViewController.TransitionHolder.storeNaviTransition(transition)
//    }
}

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
