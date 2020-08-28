//
//  UIViewController+BarItem.swift
//  FGBase
//
//  Created by kun wang on 2019/09/02.
//

import UIKit

let kNavigationBarHeight: CGFloat = 32;
extension UIViewController {
    @objc public func fg_defaultBackBarButton() -> UIButton {
        return fg_leftBarButton(with: "fg_ic_back".baseImage)
    }

    @objc(fg_leftBarButtonWithString:)
    public func fg_leftBarButton(with string: String) -> UIButton {
        return _barButton(image: nil, title: string, left: true)
    }

    @objc(fg_leftBarButtonWithImage:)
    public func fg_leftBarButton(with image: UIImage?) -> UIButton {
        return _barButton(image: image, title: nil, left: true)
    }

    @objc(fg_rightBarButtonWithString:)
    public func fg_rightBarButton(with string: String) -> UIButton {
        return _barButton(image: nil, title: string, left: false)
    }

    @objc(fg_rightBarButtonWithImage:)
    public func fg_rightBarButton(with image: UIImage?) -> UIButton {
        return _barButton(image: image, title: nil, left: false)
    }

    @objc(fg_rightBarButtonsWithImages:)
    public func fg_rightBarButtons(with images: [UIImage]) -> [UIButton] {
        return _barButtons(images: images, titles: nil, left: false)
    }

    @objc(fg_rightBarButtonsWithStrings:)
    public func fg_rightBarButtons(with strings: [String]) -> [UIButton] {
        return _barButtons(images: nil, titles: strings, left: false)
    }

    @objc(fg_barButtonWithCustomView:)
    public func fg_barButton(with customView: UIView) {
        return fg_barButton(with: customView, left: false)
    }

    @objc(fg_barButtonWithCustomView:left:)
    public func fg_barButton(with customView: UIView, left: Bool) {
        if #available(iOS 11, *) {
            let barView = AlignmentView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: customView.frame.size.width,
                                               height: customView.frame.size.height))
            barView.addSubview(customView)
            barView.translatesAutoresizingMaskIntoConstraints = false
            barView.widthAnchor.constraint(greaterThanOrEqualToConstant: barView.frame.size.width).isActive = true
            barView.heightAnchor.constraint(greaterThanOrEqualToConstant: customView.frame.size.height).isActive = true
            barView.overrideAlignmentRectInsets = alignmentRectInsets(left)
            let item = UIBarButtonItem(customView: barView)
            if left {
                navigationItem.leftBarButtonItems = [positiveSeparator(), item]
            } else {
                navigationItem.rightBarButtonItems = [positiveSeparator(), item]
            }
        } else {
            let item = UIBarButtonItem(customView: customView)
            if left {
                navigationItem.leftBarButtonItems = [negativeSeparator(), item]
            } else {
                navigationItem.rightBarButtonItems = [negativeSeparator(), item]
            }
        }
    }

    @objc(fg_barButtonWithCustomViews:)
    public func fg_barButton(with customViews: [UIView]) {
        var originX: CGFloat = 0
        let barView = AlignmentView(frame: CGRect(x: 0, y: 0, width: 0, height: kNavigationBarHeight))
        for obj in customViews {
            obj.frame = CGRect(x: originX,
                               y: CGFloat(kNavigationBarHeight/2) - obj.frame.size.height/2,
                               width: obj.frame.size.width,
                               height: obj.frame.size.height)
            originX += obj.frame.size.width
            barView.addSubview(obj)
        }
        barView.bounds = CGRect(x: 0, y: 0, width: originX, height: kNavigationBarHeight)

        if #available(iOS 11, *) {
            let item = UIBarButtonItem(customView: barView)
            barView.translatesAutoresizingMaskIntoConstraints = false
            barView.widthAnchor.constraint(greaterThanOrEqualToConstant: barView.frame.size.width).isActive = true
            barView.heightAnchor.constraint(greaterThanOrEqualToConstant: barView.frame.size.height).isActive = true
            barView.overrideAlignmentRectInsets = alignmentRectInsets(false)
            navigationItem.rightBarButtonItems = [positiveSeparator(), item]
        } else {
            let item = UIBarButtonItem(customView: barView)
            navigationItem.rightBarButtonItems = [negativeSeparator(), item]
        }
    }

    private func createButton(image: UIImage?, title: String?) -> AlignmentButton {
        let button = AlignmentButton(type: .custom)
        if let image = image {
            button.setImage(image, for: .normal)
        }

        if let title = title {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.lightText, for: .highlighted)
        }

        button.sizeToFit()
        let size = CGSize(width: 44, height: kNavigationBarHeight)
        if button.bounds.size.width < size.width {
            button.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        return button
    }

    private func _barButton(image: UIImage?, title: String?, left: Bool) -> UIButton {
        if let image = image {
            return _barButtons(images: [image], titles: nil, left: left).first ?? UIButton()
        } else if let title = title {
            return _barButtons(images: nil, titles: [title], left: left).first ?? UIButton()
        } else {
            assertionFailure("检查传入的图片或者字符串")
            return UIButton()
        }
    }

    private func _barButtons(images: [UIImage]?, titles: [String]?, left: Bool) -> [UIButton] {
        var buttons = [AlignmentButton]()
        if let images = images {
            let temp = images.map { createButton(image: $0, title: nil) }
            buttons.append(contentsOf: temp)
        } else if let titles = titles {
            let temp = titles.map { createButton(image: nil, title: $0) }
            buttons.append(contentsOf: temp)
        }

        if #available(iOS 11, *) {
            for item in buttons {
                item.translatesAutoresizingMaskIntoConstraints = false
                item.widthAnchor.constraint(greaterThanOrEqualToConstant: item.frame.size.width).isActive = true
                item.heightAnchor.constraint(greaterThanOrEqualToConstant: kNavigationBarHeight).isActive = true
                item.overrideAlignmentRectInsets = alignmentRectInsets(left)
            }
            var barButtonItems = buttons.map { UIBarButtonItem(customView: $0) }
            barButtonItems.insert(positiveSeparator(), at: 0)
            if left {
                navigationItem.leftBarButtonItems = barButtonItems
            } else {
                navigationItem.rightBarButtonItems = barButtonItems
            }
        } else {
            var barButtonItems = buttons.map { UIBarButtonItem(customView: $0) }
            barButtonItems.insert(negativeSeparator(), at: 0)
            if left {
                navigationItem.leftBarButtonItems = barButtonItems
            } else {
                navigationItem.rightBarButtonItems = barButtonItems
            }
        }
        return buttons
    }

    fileprivate func alignmentRectInsets(_ left: Bool) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: left ? 8 : -8, bottom: 0, right: left ? -8 : 8)
    }

    private func negativeSeparator() -> UIBarButtonItem {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = -16
        return fixedSpace
    }

    private func positiveSeparator() -> UIBarButtonItem {
        let positiveSeparator = UIBarButtonItem(barButtonSystemItem:.fixedSpace, target: nil, action: nil)
        positiveSeparator.width = 8
        return positiveSeparator
    }

}

class AlignmentButton: UIButton {
    var overrideAlignmentRectInsets: UIEdgeInsets?
    override var alignmentRectInsets: UIEdgeInsets {
        return overrideAlignmentRectInsets ?? super.alignmentRectInsets
    }
}

class AlignmentView: UIView {
    var overrideAlignmentRectInsets: UIEdgeInsets?
    override var alignmentRectInsets: UIEdgeInsets {
        return overrideAlignmentRectInsets ?? super.alignmentRectInsets
    }
}
