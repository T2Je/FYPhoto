//
//  UIButton+Space.swift
//  FYGOMS
//
//  Created by wangkun on 2018/1/3.
//  Copyright © 2018年 feeyo. All rights reserved.
//

import UIKit

@objc public enum ButtonImagePosition: Int {
    case left
    case top
    case bottom
    case right
}

@objc public extension UIButton {
    //
    /// 自定义image与button 位置
    ///
    /// - Parameters:
    ///   - poistion: image 相对于button 位置
    ///   - space: image 与 button 间距
    /// - 在调用该方法前可以先调用 layoutifneed 方法来强制在当前runloop中计算出 button的width height
    @objc func resizeImagePosition(poistion: ButtonImagePosition, space: CGFloat) {
        /**
         *  知识点：titleEdgeInsets是title相对于其上下左右的inset，跟tableView的contentInset是类似的，
         *  如果只有title，那它上下左右都是相对于button的，image也是一样；
         *  如果同时有image和label，那这时候image的上左下是相对于button，右边是相对于label的；title的上右下是相对于button，左边是相对于image的。
         */

        // 1. 得到imageView和titleLabel的宽、高
        let imageWidth = imageView?.image?.size.width ?? 0.0
        let imageHeight = imageView?.image?.size.height ?? 0.0

        var labelWidth = self.titleLabel?.frame.size.width ?? 0.0
        var labelHeight = self.titleLabel?.frame.size.height ?? 0.0

        // 如果frame.size 取不到值，就用intrinsicContentSize
        labelWidth = labelWidth == 0 ? (titleLabel?.intrinsicContentSize.width ?? 0) : labelWidth
        labelHeight = labelHeight == 0 ? (titleLabel?.intrinsicContentSize.height ?? 0) : labelHeight

        // 2. 声明全局的imageEdgeInsets和labelEdgeInsets
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero

        // 3. 根据style和space得到imageEdgeInsets和labelEdgeInsets的值
        switch poistion {
        case .top:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight-space/2.0, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: -imageHeight-space/2.0, right: 0)
        case .left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space/2.0, bottom: 0, right: space/2.0)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: space/2.0, bottom: 0, right: -space/2.0)
        case .bottom:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight-space/2.0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: -imageHeight-space/2.0, left: -imageWidth, bottom: 0, right: 0)
        case .right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth+space/2.0, bottom: 0, right: -labelWidth-space/2.0)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth-space/2.0, bottom: 0, right: imageWidth+space/2.0)
        }

        // 4. 赋值
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}
