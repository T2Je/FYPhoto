//
//  UITabBar+RedAlert.swift
//  FGBase
//
//  Created by kun wang on 2019/09/02.
//

import UIKit

private let kBadgeViewTag = 200

extension UITabBar {

    @objc public func showBadge(at itemIndex: Int) {
        removeBadge(at: itemIndex)
        let kBadgeWidth: CGFloat = 6
        let badgeView = UIView()
        badgeView.tag = kBadgeViewTag + itemIndex
        badgeView.layer.cornerRadius = CGFloat(kBadgeWidth/2)
        badgeView.backgroundColor = .red
        addSubview(badgeView)

        // 设置小红点的位置
        let sortedViews = subviews.sorted { $0.frame.origin.x < $1.frame.origin.x
        }
        var i = 0
        guard let aClass = NSClassFromString("UITabBarButton") else {
            return
        }
        for subView in sortedViews where subView.isKind(of: aClass) {
            if i == itemIndex {
                let x = subView.frame.origin.x + subView.frame.width / 2 + 9
                let y = 6
                badgeView.frame = CGRect(x: x, y: CGFloat(y), width: kBadgeWidth, height: kBadgeWidth)
            }
            i += 1
        }
    }

    @objc public func hideBadge(at itemIndex: Int) {
        removeBadge(at: itemIndex)
    }

    private func removeBadge(at itemIndex: Int) {
        for view in subviews where view.tag == kBadgeViewTag + itemIndex {
            view.removeFromSuperview()
        }
    }
}
