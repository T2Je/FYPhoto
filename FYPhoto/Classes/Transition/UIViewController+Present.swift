//
//  UIViewController+Present.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

extension UIViewController: FYNameSpaceProtocol {
    struct TransitionHolder {
        static var _holderValue: PhotoPresentTransitionController?
    }
}

extension TypeWrapper {
    
}
extension TypeWrapperProtocol where WrappedType: UIViewController {
    
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        
        let transition = PhotoPresentTransitionController(viewController: viewControllerToPresent)
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.transitioningDelegate = transition
        wrappedValue.present(viewControllerToPresent, animated: animated, completion: {
            completion?()
        })
//        wrappedValue.present(viewControllerToPresent, animated: animated, completion: completion)
        UIViewController.TransitionHolder._holderValue = transition
    }
}
