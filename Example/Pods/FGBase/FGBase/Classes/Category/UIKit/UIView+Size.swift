//
//  UIView+Size.swift
//  FGBase
//
//  Created by kun wang on 2020/08/03.
//

import Foundation

extension UIView {
    @objc public var size: CGSize {
        get { return frame.size }
        set { frame = CGRect(origin: frame.origin, size: newValue) }
    }

    @objc public var left: CGFloat {
        get { return frame.minX }
        set {
            var temp = frame
            temp.origin.x = newValue
            frame = temp
        }
    }

    @objc public var top: CGFloat {
        get { return frame.minY }
        set {
            var temp = frame
            temp.origin.y = newValue
            frame = temp
        }
    }

    @objc public var right: CGFloat {
        get { return frame.maxX }
        set {
            var temp = frame
            temp.origin.x = newValue - frame.size.width
            frame = temp
        }
    }

    @objc public var bottom: CGFloat {
        get { return frame.maxY }
        set {
            var temp = frame
            temp.origin.y = newValue - frame.size.height
            frame = temp
        }
    }

    @objc public var centerX: CGFloat {
        get { return center.x }
        set { center = CGPoint(x: newValue, y: center.y) }
    }

    @objc public var centerY: CGFloat {
        get { return center.y }
        set { center = CGPoint(x: center.x, y: newValue) }
    }

    @objc public var width: CGFloat {
        get { return frame.width }
        set {
            var temp = frame
            temp.size.width = newValue
            frame = temp
        }
    }

    @objc public var height: CGFloat {
        get { return frame.height }
        set {
            var temp = frame
            temp.size.height = newValue
            frame = temp
        }
    }
}
