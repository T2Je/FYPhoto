//
//  UIResponder+routerEvent.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation

extension UIResponder {
    @objc func routerEvent(name: String, userInfo: [AnyHashable: Any]?) {
        next?.routerEvent(name: name, userInfo: userInfo)
    }
}
