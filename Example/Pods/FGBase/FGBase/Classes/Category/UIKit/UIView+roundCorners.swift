//
//  UIView+roundCorners.swift
//  FGBase
//
//  Created by xiaoyang on 2019/10/31.
//

import Foundation

extension UIView {

    /// method for set specified corner's cornerRadius of UIView. Use this method after calling layoutIfNeed if it works weird
    /// - Parameter roundingCorners: [.topLeft, .topRight, bottomLeft, bottomRight]
    /// - Parameter cornerRadius: cornerRadius
    public func rounderCorners(byRoundingCorners roundingCorners: UIRectCorner, cornerRadius: CGFloat) {
        let maskPath: UIBezierPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        maskLayer.backgroundColor = UIColor.clear.cgColor
        self.layer.mask = maskLayer
    }
}
