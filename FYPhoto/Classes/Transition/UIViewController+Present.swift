//
//  UIViewController+Present.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

extension UIViewController: FYNameSpaceProtocol {}

public extension TypeWrapperProtocol where WrappedType == UIViewController {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let transition = PhotoPresentTransitionController(viewController: wrappedValue)
        wrappedValue.transitioningDelegate = transition
        wrappedValue.present(viewControllerToPresent, animated: animated, completion: completion)
    }
}
