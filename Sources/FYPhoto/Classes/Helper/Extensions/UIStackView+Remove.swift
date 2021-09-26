//
//  UIStackView+Remove.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/8.
//

import Foundation
import UIKit

extension UIStackView {

    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }

}
