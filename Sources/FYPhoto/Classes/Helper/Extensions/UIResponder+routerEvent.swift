//
//  UIResponder+routerEvent.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation
import UIKit

extension UIResponder {
    @objc func routerEvent(name: String, userInfo: [AnyHashable: Any]?) {
        next?.routerEvent(name: name, userInfo: userInfo)
    }
}
