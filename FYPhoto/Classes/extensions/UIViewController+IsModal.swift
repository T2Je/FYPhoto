//
//  UIViewController+IsModal.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/25.
//

import Foundation

extension UIViewController {
    var isModal: Bool {

        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}
