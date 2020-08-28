//
//  UIViewController+Popup.swift
//  FGBase
//
//  Created by xiaoyang on 2019/9/12.
//

import Foundation

extension UIViewController {
    private struct SlideInAssociatedKeys {
        static var slideInPresentationDelegate = "UIViewController.slideInPresentationDelegate"
    }

    private var slideInPresentationDelegate: SlideInPresentationManager {
        get {
            guard let value = objc_getAssociatedObject(self, &SlideInAssociatedKeys.slideInPresentationDelegate) as? SlideInPresentationManager else {
                return SlideInPresentationManager()
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &SlideInAssociatedKeys.slideInPresentationDelegate, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


    @objc public func presentSlideIn(_ viewController: UIViewController,
                                     animated: Bool,
                                     direction: PresentationDirection,
                                     offset: CGPoint = .zero,
                                     completion: (() -> Void)?,
                                     dismissed: (() -> Void)?) {
        slideInPresentationDelegate = SlideInPresentationManager()
        slideInPresentationDelegate.direction = direction
        slideInPresentationDelegate.offset = offset
        slideInPresentationDelegate.size = viewController.view.frame.size
        slideInPresentationDelegate.dismissed = dismissed
        viewController.transitioningDelegate = slideInPresentationDelegate
        viewController.modalPresentationStyle = .custom

        self.present(viewController, animated: animated, completion: completion)
    }

    @objc public func presentSlideIn(_ viewController: UIViewController, direction: PresentationDirection, offset: CGPoint = .zero) {
        self.presentSlideIn(viewController, animated: true, direction: direction, offset: offset, completion: nil, dismissed: nil)
    }

    @objc public func dismissSlideInViewController(animated: Bool, completion: (() -> Void)?) {
        presentedViewController?.dismiss(animated: animated, completion: completion)
        slideInPresentationDelegate.dismissed?()
        slideInPresentationDelegate.dismissed = nil
    }
}
