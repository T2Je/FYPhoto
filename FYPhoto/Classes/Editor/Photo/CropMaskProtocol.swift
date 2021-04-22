//
//  CropMaskProtocol.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import Foundation

protocol CropMaskProtocol where Self: UIView {
        
    func setMask(_ insideRect: CGRect)
}

extension CropMaskProtocol {
    func createTransparentRect(withOutside outsideRect: CGRect, insideRect: CGRect, opacity: Float) -> CALayer {
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
}
