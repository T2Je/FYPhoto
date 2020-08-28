//
//  FYNavigationController.swift
//  FYNavigationController
//
//  Created by kun wang on 2018/7/17.
//  Copyright © 2018年 Feeyo. All rights reserved.
//

import UIKit


/* 解决了自定义navigationitem导致左滑失效问题
 * 解决了push时隐藏Tabbar问题
 */
@objc public class FYNavigationController: UINavigationController {

    override public func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    @objc override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        interactivePopGestureRecognizer?.isEnabled = true
        super.pushViewController(viewController, animated: animated)
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .lightContent
    }
}

extension FYNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let interactivePopGesture = interactivePopGestureRecognizer else { return true }
        guard let visibleViewController = visibleViewController else { return true }
        guard let firstViewController = viewControllers.first else { return true }
        if interactivePopGesture == gestureRecognizer {
            if viewControllers.count < 2 || visibleViewController == firstViewController {
                return false
            }
        }
        return true
    }
}
