//
//  CropDimmingView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropDimmingView: UIView, CropMaskProtocol {
    var transparentLayer: CAShapeLayer?

    func setMask(_ insideRect: CGRect, animated: Bool) {
        guard self.bounds.size != .zero else {
            return
        }

        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.5)

        if let shapeLayer = transparentLayer {
            if animated {
                animateTransparentLayer(shapeLayer, withOutside: bounds, insideRect: insideRect, opacity: 0.5)
            } else {
                shapeLayer.path = layer.path
            }
        } else {
            self.layer.addSublayer(layer)
            transparentLayer = layer
        }
    }
}
