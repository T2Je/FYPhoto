//
//  UIStackView+Remove.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/8.
//

import Foundation

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
