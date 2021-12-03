//
//  CropMaskProtocol.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import Foundation
import UIKit

protocol CropMaskProtocol where Self: UIView {
    var transparentLayer: CAShapeLayer? { get set }
    func setMask(_ insideRect: CGRect, animated: Bool)
}

extension CropMaskProtocol {
    func createTransparentRect(withOutside outsideRect: CGRect, insideRect: CGRect, opacity: Float) -> CAShapeLayer {
        let path = UIBezierPath(rect: outsideRect)

        let innerPath = UIBezierPath(rect: insideRect)

        path.append(innerPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = opacity
        return fillLayer
    }

    func animateTransparentLayer(_ shapeLayer: CAShapeLayer, withOutside outsideRect: CGRect, insideRect: CGRect, opacity: Float) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = shapeLayer.path
        addTransparentRect(on: shapeLayer, withOutside: outsideRect, insideRect: insideRect, opacity: opacity)
        animation.toValue = shapeLayer.path
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // Avoid animation vibration, but still not smooth enough.
        shapeLayer.add(animation, forKey: "pathAnimation")
    }

    func addTransparentRect(on fillLayer: CAShapeLayer, withOutside outsideRect: CGRect, insideRect: CGRect, opacity: Float) {
        let path = UIBezierPath(rect: outsideRect)
        let innerPath = UIBezierPath(rect: insideRect)

        path.append(innerPath)
        path.usesEvenOddFillRule = true

        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = opacity
    }
}
